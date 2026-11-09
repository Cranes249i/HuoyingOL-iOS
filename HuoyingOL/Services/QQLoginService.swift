//
//  QQLoginService.swift
//  HuoyingOL
//
//  QQ登录服务
//  处理QQ OAuth2.0 URL构造、回调解析和会话管理
//

import Foundation
import WebKit

/// QQ登录服务
/// 负责构造QQ OAuth授权URL、解析回调参数、管理登录会话
class QQLoginService {
    // MARK: - 常量
    
    /// QQ应用ID
    private let appId = AppSettings.qqAppId
    /// OAuth回调Scheme
    private let callbackScheme = AppSettings.qqCallbackScheme
    /// QQ OAuth授权基础URL
    private let oauthBaseURL = "https://graph.qq.com/oauth2.0/authorize"
    /// QQ登录页面URL
    private let loginPageURL = "https://xui.ptlogin2.qq.com/cgi-bin/xlogin"
    /// QQ跳转验证URL前缀
    private let jumpURLPrefix = "https://ssl.ptlogin2.qq.com/jump"
    
    /// 需要处理的QQ相关域名
    static let qqDomains = [
        "xui.ptlogin2.qq.com",
        "ssl.ptlogin2.qq.com",
        "graph.qq.com",
        "huoying.qq.com"
    ]
    
    // MARK: - URL构造
    
    /// 构造QQ OAuth授权URL
    /// - Parameters:
    ///   - display: 显示模式 ("pc" 或 "mobile")
    ///   - state: OAuth state参数（防CSRF）
    /// - Returns: 完整的OAuth授权URL
    func buildOAuthURL(display: String = "pc", state: String? = nil) -> URL? {
        var components = URLComponents(string: oauthBaseURL)
        var queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: appId),
            URLQueryItem(name: "redirect_uri", value: "\(callbackScheme)://login"),
            URLQueryItem(name: "display", value: display),
            URLQueryItem(name: "scope", value: "get_user_info")
        ]
        
        if let state = state {
            queryItems.append(URLQueryItem(name: "state", value: state))
        }
        
        components?.queryItems = queryItems
        return components?.url
    }
    
    /// 构造QQ登录页面URL
    /// - Returns: QQ登录页面完整URL
    func buildLoginPageURL() -> URL? {
        var components = URLComponents(string: loginPageURL)
        components?.queryItems = [
            URLQueryItem(name: "daid", value: "207"),
            URLQueryItem(name: "target", value: "self"),
            URLQueryItem(name: "appid", value: "7000201")
        ]
        return components?.url
    }
    
    /// 构造小游戏入口URL（用于QQ快捷登录）
    /// - Returns: 小游戏入口URL
    func buildMiniGameURL() -> URL? {
        var components = URLComponents(string: AppSettings.miniGameURL)
        components?.queryItems = [
            URLQueryItem(name: "appid", value: appId)
        ]
        return components?.url
    }
    
    // MARK: - 回调处理
    
    /// 判断URL是否为QQ回调URL
    /// - Parameter url: 待判断的URL
    /// - Returns: 是否为回调URL
    func isCallbackURL(_ url: URL) -> Bool {
        return url.scheme == callbackScheme
    }
    
    /// 判断URL是否为QQ登录跳转URL
    /// - Parameter url: 待判断的URL
    /// - Returns: 是否为跳转URL
    func isJumpURL(_ url: URL) -> Bool {
        return url.absoluteString.hasPrefix(jumpURLPrefix)
    }
    
    /// 判断URL是否属于QQ登录相关域名
    /// - Parameter url: 待判断的URL
    /// - Returns: 是否为QQ相关URL
    func isQQRelatedURL(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return QQLoginService.qqDomains.contains(host)
    }
    
    /// 解析OAuth回调URL中的参数
    /// - Parameter url: 回调URL
    /// - Returns: 解析结果，包含code、access_token、openid等
    func parseCallbackURL(_ url: URL) -> OAuthCallbackResult? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        let queryItems = components.queryItems ?? []
        var params: [String: String] = [:]
        for item in queryItems {
            if let value = item.value {
                params[item.name] = value
            }
        }
        
        // 也检查fragment中的参数（隐式授权模式）
        if let fragment = components.fragment {
            let fragmentComponents = URLComponents(string: "?\(fragment)")
            for item in fragmentComponents?.queryItems ?? [] {
                if let value = item.value {
                    params[item.name] = value
                }
            }
        }
        
        return OAuthCallbackResult(
            code: params["code"],
            accessToken: params["access_token"],
            openId: params["openid"],
            expiresIn: params["expires_in"],
            state: params["state"],
            error: params["error"],
            errorDescription: params["error_description"]
        )
    }
    
    /// 从Cookie中提取登录信息
    /// - Parameter cookies: HTTP Cookie数组
    /// - Returns: 提取的登录信息
    func extractLoginInfo(from cookies: [HTTPCookie]) -> LoginInfo? {
        var openId: String?
        var accessToken: String?
        var nickname: String?
        
        for cookie in cookies {
            switch cookie.name {
            case "openid":
                openId = cookie.value
            case "access_token":
                accessToken = cookie.value
            case "nickname":
                nickname = cookie.value
            default:
                break
            }
        }
        
        guard let oId = openId else { return nil }
        
        return LoginInfo(
            openId: oId,
            accessToken: accessToken,
            nickname: nickname
        )
    }
    
    // MARK: - 会话管理
    
    /// 清除指定WebView的QQ登录Cookie
    /// - Parameter dataStore: WKWebsiteDataStore实例
    func clearLoginSession(dataStore: WKWebsiteDataStore, completion: @escaping () -> Void) {
        let cookieStore = dataStore.httpCookieStore
        cookieStore.getAllCookies { cookies in
            let qqCookies = cookies.filter { cookie in
                QQLoginService.qqDomains.contains(where: { cookie.domain.contains($0) })
            }
            
            let group = DispatchGroup()
            for cookie in qqCookies {
                group.enter()
                cookieStore.delete(cookie) {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                print("🗑️ 已清除 \(qqCookies.count) 个QQ登录Cookie")
                completion()
            }
        }
    }
}

// MARK: - 数据模型

/// OAuth回调结果
struct OAuthCallbackResult {
    let code: String?
    let accessToken: String?
    let openId: String?
    let expiresIn: String?
    let state: String?
    let error: String?
    let errorDescription: String?
    
    var isSuccess: Bool {
        return error == nil && (code != nil || accessToken != nil)
    }
}

/// 登录信息
struct LoginInfo {
    let openId: String
    let accessToken: String?
    let nickname: String?
}
