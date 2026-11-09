//
//  RuffleSchemeHandler.swift
//  HuoyingOL
//
//  把随包的 Ruffle（ruffle.js / core / wasm）和跨域 SWF 交给 WKWebView。
//  页面是 https，CDN 的 entry.swf 没有 CORS，浏览器里的 fetch 会被拦住，所以由这里代为下载。
//
//  已知限制：火影 OL 的 entry.swf 是 ActionScript 3，并用 Flash Socket 连 zone.huoying.qq.com。
//  Ruffle 0.7 不能直接做 TCP Socket，只能走 socketProxy（本仓库没有配套代理）。
//  舞台可以起来，连区服端口时仍可能失败。下一步才是自建 TCP→WebSocket 代理，或换能跑 AIR 的运行时。
//

import Foundation
import WebKit

final class RuffleSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "ruffle"

    private let lock = NSLock()
    private var stoppedTasks = Set<ObjectIdentifier>()
    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        config.httpShouldSetCookies = false
        return URLSession(configuration: config)
    }()

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            fail(urlSchemeTask, URLError(.badURL))
            return
        }
        if urlSchemeTask.request.httpMethod?.uppercased() == "OPTIONS" {
            finish(urlSchemeTask, url: url, status: 204, mime: "text/plain", data: Data())
            return
        }
        switch url.host?.lowercased() {
        case "bundle":
            if serveWasmAsScript(url, task: urlSchemeTask) {
                return
            }
            serveBundle(url, task: urlSchemeTask)
        case "proxy":
            serveProxy(url, webView: webView, task: urlSchemeTask)
        default:
            fail(urlSchemeTask, URLError(.unsupportedURL))
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        lock.lock()
        stoppedTasks.insert(ObjectIdentifier(urlSchemeTask))
        lock.unlock()
    }

    /// WKWebView 的 fetch() 往往到不了自定义 scheme，instantiateStreaming 也会拒绝这种响应。
    /// 把 wasm 切成 base64 脚本，用 script 标签加载（scheme 对 script src 有效），再由页面拼成带 application/wasm 的 Response。
    private static let wasmChunkChars = 524288

    private func serveWasmAsScript(_ url: URL, task: WKURLSchemeTask) -> Bool {
        let pieces = url.path.split(separator: "/").map(String.init)
        guard pieces.count == 3, pieces[0] == "wasm" else { return false }
        let name = pieces[1]
        let part = pieces[2]
        guard Self.isSafeWasmName(name), let file = Self.bundleFile(named: name) else {
            fail(task, URLError(.fileDoesNotExist))
            return true
        }
        do {
            let base64 = try Data(contentsOf: file).base64EncodedString()
            let javascript: String
            if part == "manifest.js" {
                let count = max(1, (base64.count + Self.wasmChunkChars - 1) / Self.wasmChunkChars)
                javascript = "window.__airWasmCount=window.__airWasmCount||{};window.__airWasmCount[\""
                    + name + "\"]=" + String(count)
                    + ";window.__airWasmParts=window.__airWasmParts||{};window.__airWasmParts[\""
                    + name + "\"]=\"\";"
            } else if part.hasSuffix(".js"), let index = Int(part.dropLast(3)), index >= 0 {
                let start = index * Self.wasmChunkChars
                guard start < base64.count else {
                    fail(task, URLError(.fileDoesNotExist))
                    return true
                }
                let end = min(start + Self.wasmChunkChars, base64.count)
                let from = base64.index(base64.startIndex, offsetBy: start)
                let to = base64.index(base64.startIndex, offsetBy: end)
                javascript = "window.__airWasmParts[\"" + name + "\"]+=\"" + String(base64[from..<to]) + "\";"
            } else {
                return false
            }
            finish(task, url: url, status: 200, mime: "text/javascript", data: Data(javascript.utf8))
        } catch {
            fail(task, error)
        }
        return true
    }

    private static func isSafeWasmName(_ name: String) -> Bool {
        guard name.hasSuffix(".wasm"), !name.contains("/"), !name.contains("..") else { return false }
        return name.unicodeScalars.allSatisfy { scalar in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "." || scalar == "_" || scalar == "-"
        }
    }

    private func serveBundle(_ url: URL, task: WKURLSchemeTask) {
        let name = url.lastPathComponent
        guard !name.isEmpty, !name.contains("/"), !name.contains(".."),
              let file = Self.bundleFile(named: name) else {
            fail(task, URLError(.fileDoesNotExist))
            return
        }
        do {
            let data = try Data(contentsOf: file)
            finish(task, url: url, status: 200, mime: Self.mime(for: name), data: data)
        } catch {
            fail(task, error)
        }
    }

    private func serveProxy(_ url: URL, webView: WKWebView, task: WKURLSchemeTask) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let raw = components.queryItems?.first(where: { $0.name == "url" })?.value,
              let target = URL(string: raw),
              let scheme = target.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              !Self.isBlockedHost(target) else {
            fail(task, URLError(.badURL))
            return
        }
        // WKURLSchemeTask 的回调必须留在 start 所在线程，所以在这里等下载结束。
        let semaphore = DispatchSemaphore(value: 0)
        var body = Data()
        var mime = Self.mime(for: target.path)
        var status = 200
        var failure: Error?
        var request = URLRequest(url: target)
        request.httpMethod = "GET"
        let dataTask = session.dataTask(with: request) { data, response, error in
            if let error = error {
                failure = error
            } else {
                body = data ?? Data()
                if let http = response as? HTTPURLResponse {
                    status = http.statusCode
                    if let responseMime = http.mimeType, !responseMime.isEmpty {
                        mime = responseMime
                    }
                }
            }
            semaphore.signal()
        }
        dataTask.resume()
        semaphore.wait()
        _ = webView
        if let failure = failure {
            fail(task, failure)
            return
        }
        finish(task, url: url, status: status, mime: mime, data: body)
    }

    private func finish(_ task: WKURLSchemeTask, url: URL, status: Int, mime: String, data: Data) {
        if isStopped(task) { return }
        let headers = [
            "Content-Type": mime,
            "Content-Length": String(data.count),
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
            "Access-Control-Allow-Headers": "*",
            "Cache-Control": "public, max-age=86400"
        ]
        guard let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers) else {
            fail(task, URLError(.badServerResponse))
            return
        }
        if isStopped(task) { return }
        task.didReceive(response)
        if isStopped(task) { return }
        if !data.isEmpty {
            task.didReceive(data)
        }
        if isStopped(task) { return }
        task.didFinish()
    }

    private func fail(_ task: WKURLSchemeTask, _ error: Error) {
        if isStopped(task) { return }
        task.didFailWithError(error)
    }

    private func isStopped(_ task: WKURLSchemeTask) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return stoppedTasks.contains(ObjectIdentifier(task))
    }

    private static func bundleFile(named name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "Ruffle") {
            return url
        }
        if let root = Bundle.main.resourceURL?.appendingPathComponent("Ruffle", isDirectory: true) {
            let file = root.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: file.path) {
                return file
            }
        }
        return Bundle.main.url(forResource: name, withExtension: nil)
    }

    private static func mime(for name: String) -> String {
        let lower = name.lowercased()
        if lower.hasSuffix(".wasm") { return "application/wasm" }
        if lower.hasSuffix(".js") { return "text/javascript" }
        if lower.hasSuffix(".swf") { return "application/x-shockwave-flash" }
        return "application/octet-stream"
    }

    private static func isBlockedHost(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased(), !host.isEmpty else { return true }
        if host == "localhost" || host.hasSuffix(".local") || host == "0.0.0.0" || host == "::1" {
            return true
        }
        if host.hasPrefix("127.") || host.hasPrefix("10.") || host.hasPrefix("192.168.") || host.hasPrefix("169.254.") {
            return true
        }
        return false
    }

}
