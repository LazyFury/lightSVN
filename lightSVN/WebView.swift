import SwiftUI
import WebKit
import AppKit

let sharedProcessPool = WKProcessPool()


struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.configuration.processPool = sharedProcessPool
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // 如果需要更新 URL，在此处执行
    }
}
