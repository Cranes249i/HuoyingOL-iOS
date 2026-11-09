//
//  GameWebView.swift
//  HuoyingOL
//
//  游戏WKWebView包装视图
//  通过UIViewRepresentable桥接WebKit，注入qq-return.js、自定义UserAgent、处理多账号Cookie隔离与QQ OAuth回调
//

import SwiftUI
import WebKit

/// 游戏WKWebView包装器
/// 负责承载火影OL网页游戏界面，注入关键JS脚本，管理网络请求生命周期
struct GameWebView: UIViewRepresentable {
    @ObservedObject var viewModel: GameViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // 允许内联媒体播放
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        // 注入 qq-return.js 脚本 (在所有子frame中执行，用于处理跨iframe登录通信)
        injectQQReturnScript(into: configuration.userContentController)
        
        // 创建独立的或者持久化的 WKWebView
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // 禁用页面反弹阻尼感，获得类似原生游戏的全屏体验
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = true
        webView.backgroundColor = .black
        
        // 自定义 User-Agent，附加 HuoyingAIR/0.2 特征标志
        let defaultUA = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
        webView.customUserAgent = "\(defaultUA) \(AppSettings.customUserAgent)"
        
        // 绑定引用到 ViewModel
        viewModel.webView = webView
        
        // 监听 WebView 进度和状态
        context.coordinator.setupObservers(for: webView)
        
        // 恢复该账号持久化的 Cookie
        viewModel.restoreCookies()
        
        // 加载主页
        viewModel.loadGamePage()
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // ViewModel 驱动变更，由服务层直接执行 evaluateJavaScript
    }
    
    /// 注入 QQ 回调代理通信脚本
    private func injectQQReturnScript(into contentController: WKUserContentController) {
        var scriptSource = ""
        
        // 优先从应用 Bundle 中加载 qq-return.js
        if let fileURL = Bundle.main.url(forResource: "qq-return", withExtension: "js"),
           let content = try? String(contentsOf: fileURL, encoding: .utf8) {
            scriptSource = content
        } else {
            // 内置兜底脚本实现
            scriptSource = """
            (() => {
             const home="https://huoying.qq.com", graph="https://graph.qq.com";
             const login=["https://xui.ptlogin2.qq.com","https://ssl.ptlogin2.qq.com"];
             const type="huoying-air-qq-return-v1", origin=location.origin;
             if(window.top===window&&origin===home){
              let modeTimer,activeMode;
              function wireZoneLogin(){
               if(typeof window.loginNew!=="function"||typeof window.QcGameLogin!=="function"||window.loginNew.airNativeLogin)return;
               const original=window.loginNew;
               window.loginNew=function(id){
                const cookies=new Set(document.cookie.split(";").map(x=>x.trim().split("=")[0]));
                if(window.iUseQQConnect!=1||!cookies.has("openid")||!cookies.has("access_token"))return original.apply(this,arguments);
                if(!window.JSON_server?.[id]&&window.all_JSON_server?.[id])window.JSON_server=window.all_JSON_server;
                const server=window.JSON_server?.[id];
                if(!server||server.sServerStatus==0)return original.apply(this,arguments);
                return window.QcGameLogin(id);
               };
               window.loginNew.airNativeLogin=true;
              }
              wireZoneLogin();addEventListener("DOMContentLoaded",wireZoneLogin);addEventListener("load",wireZoneLogin);
              if(!window.loginNew?.airNativeLogin){
               const until=Date.now()+120000;
               const probe=setInterval(()=>{wireZoneLogin();if(window.loginNew?.airNativeLogin||Date.now()>until)clearInterval(probe);},250);
              }
              function send(data){
               for(const frame of document.querySelectorAll('iframe')) {
                let target;try{target=new URL(frame.src).origin;}catch{continue;}
                if(target===graph||login.includes(target))for(const destination of [graph,...login])frame.contentWindow.postMessage(data,destination);
               }
              }
              window.airQqReturn={accepted:false,accept(url){
               this.accepted=false;
               send({type,action:"return",url});
              },mode(kind){
               if(kind!=="password"&&kind!=="qq")return;
               activeMode=kind;
               clearInterval(modeTimer);
               for(const frame of document.querySelectorAll('iframe')){
                let u;try{u=new URL(frame.src);}catch{continue;}
                if(u.origin===graph&&["/oauth2.0/authorize","/oauth2.0/show"].includes(u.pathname)){
                 u.pathname="/oauth2.0/authorize";if(kind==="qq")u.searchParams.set("display","mobile");else u.searchParams.delete("display");
                 frame.dataset.airQqMode=kind;frame.src=u.href;
                }
               }
               const attempt=String(Date.now()),started=Date.now(),deadline=started+60000;
               let opened=false,lastOpen=0;
               modeTimer=setInterval(()=>{
                wireZoneLogin();
                if(Date.now()>deadline){clearInterval(modeTimer);return;}
                const exists=[...document.querySelectorAll('iframe')].some(f=>{try{return [graph,...login].includes(new URL(f.src).origin);}catch{return false;}});
                if(exists)opened=true;
                if(!exists&&!opened&&Date.now()-started>=500&&Date.now()-lastOpen>=1000){lastOpen=Date.now();document.getElementById('dologin')?.click();}
                if(kind==="qq")for(const frame of document.querySelectorAll('iframe')){
                 let u;try{u=new URL(frame.src);}catch{continue;}
                 if(u.origin===graph&&["/oauth2.0/authorize","/oauth2.0/show"].includes(u.pathname)&&!frame.dataset.airQqMode){
                  frame.dataset.airQqMode="1";u.pathname="/oauth2.0/authorize";u.searchParams.set("display","mobile");frame.src=u.href;
                 }
                }
                send({type,action:kind,attempt});
               },250);
              }};
              addEventListener('message',e=>{
               if(e.data?.type===type&&e.data.action==="accepted"&&(e.origin===graph||login.includes(e.origin))&&
                 [...document.querySelectorAll('iframe')].some(f=>f.contentWindow===e.source))window.airQqReturn.accepted=true;
               if(e.data?.type===type&&e.data.action==="mode-ready"&&(e.origin===graph||login.includes(e.origin))&&
                 [...document.querySelectorAll('iframe')].some(f=>f.contentWindow===e.source)&&activeMode==="qq")clearInterval(modeTimer);
              });return;
             }
             if(origin!==graph&&!login.includes(origin))return;
             let issued;
             addEventListener('message',e=>{
              const d=e.data;if(d?.type!==type)return;
              if(origin===graph&&["accepted","mode-ready"].includes(d.action)&&login.includes(e.origin)&&
                [...document.querySelectorAll('iframe')].some(f=>f.contentWindow===e.source)){
               window.parent.postMessage({type,action:d.action},home);return;
              }
              if(e.source!==window.parent)return;
              if(origin===graph){
               if(e.origin!==home)return;
               for(const f of document.querySelectorAll('iframe'))for(const target of login)f.contentWindow.postMessage(d,target);
              }else if((e.origin===home||e.origin===graph)&&d.action==="return"&&typeof d.url==="string"){
               let u;try{u=new URL(d.url);}catch{return;}
               if(u.origin!=="https://ssl.ptlogin2.qq.com"||u.pathname!=="/jump"||u.username||u.password||u.hash)return;
               window.parent.postMessage({type,action:"accepted"},e.origin);location.replace(u.href);
              }else if((e.origin===home||e.origin===graph)&&typeof d.attempt==="string"&&issued!==d.attempt){
               if(d.action==="password"&&document.getElementById('switcher_plogin')){
                if(document.readyState!=="complete"||typeof window.pt?.plogin?.switchpage!=="function")return;
                document.getElementById('switcher_plogin').click();
                if(window.pt.plogin.loginState!==1||!(document.getElementById('p')?.getBoundingClientRect().height>0))return;
                issued=d.attempt;
               }else if(d.action==="qq"&&window.pt?.hasInit&&typeof window.pt.doOneKey==="function"){
                issued=d.attempt;window.pt.isAndroid=true;window.pt.doOneKey();
               }else return;
               window.parent.postMessage({type,action:"mode-ready"},e.origin);
              }
             });
            })();
            """
        }
        
        let userScript = WKUserScript(
            source: scriptSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        contentController.addUserScript(userScript)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var viewModel: GameViewModel
        private var progressObservation: NSKeyValueObservation?
        private var titleObservation: NSKeyValueObservation?
        private var urlObservation: NSKeyValueObservation?
        private var loadingObservation: NSKeyValueObservation?
        
        init(viewModel: GameViewModel) {
            self.viewModel = viewModel
            super.init()
        }
        
        deinit {
            progressObservation?.invalidate()
            titleObservation?.invalidate()
            urlObservation?.invalidate()
            loadingObservation?.invalidate()
        }
        
        func setupObservers(for webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.viewModel.updateProgress(wv.estimatedProgress)
                }
            }
            
            titleObservation = webView.observe(\.title, options: [.new]) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.viewModel.updateTitle(wv.title)
                }
            }
            
            urlObservation = webView.observe(\.url, options: [.new]) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.viewModel.updateURL(wv.url)
                }
            }
            
            loadingObservation = webView.observe(\.isLoading, options: [.new]) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.viewModel.updateLoadingState(wv.isLoading)
                }
            }
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            // 拦截 QQ 登录自定义回调 URL Scheme (huoyingairqq://login)
            if url.scheme == AppSettings.qqCallbackScheme {
                viewModel.handleQQCallback(url: url)
                decisionHandler(.cancel)
                return
            }
            
            // 拦截 QQ 手机客户端快捷登录协议 (wtloginmqq://)
            if url.scheme == "wtloginmqq" || url.scheme == "mqq" {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            viewModel.updateLoadingState(false)
            viewModel.onPageFinishLoad()
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            viewModel.updateLoadingState(false)
            viewModel.errorMessage = error.localizedDescription
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            viewModel.updateLoadingState(false)
            viewModel.errorMessage = error.localizedDescription
        }
        
        // MARK: - WKUIDelegate (处理 window.open / 弹窗)
        
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            // 在同一 WebView 中加载弹出的网页链接
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}
