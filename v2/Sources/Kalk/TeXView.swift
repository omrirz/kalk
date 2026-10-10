import SwiftUI
import WebKit

/// Typesets TeX with KaTeX, like the Electron version. Reports the rendered height through `height`.
struct TeXView: NSViewRepresentable {
    let tex: String
    let color: NSColor
    let fontSize: CGFloat
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(height: $height)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: "size")
        let webView = PassiveWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        if let page = Self.pageURL {
            webView.loadFileURL(page, allowingReadAccessTo: page.deletingLastPathComponent())
        }
        context.coordinator.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.height = $height
        context.coordinator.render(tex: tex, color: color, fontSize: fontSize)
    }

    /// In the .app bundle the page sits in Contents/Resources/Web; under `swift run` it's in the SwiftPM bundle.
    private static var pageURL: URL? {
        Bundle.main.url(forResource: "math", withExtension: "html", subdirectory: "Web")
            ?? Bundle.module.url(forResource: "math", withExtension: "html", subdirectory: "Web")
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var height: Binding<CGFloat>
        weak var webView: WKWebView?
        private var isLoaded = false
        private var pending: (tex: String, color: NSColor, fontSize: CGFloat)?

        init(height: Binding<CGFloat>) {
            self.height = height
        }

        func render(tex: String, color: NSColor, fontSize: CGFloat) {
            pending = (tex, color, fontSize)
            guard isLoaded, let webView, let pending else { return }

            let rgb = color.usingColorSpace(.sRGB) ?? .white
            let css = "rgb(\(Int(rgb.redComponent * 255)), \(Int(rgb.greenComponent * 255)), \(Int(rgb.blueComponent * 255)))"
            // JSON-encode the TeX so backslashes and quotes reach JavaScript intact.
            let texJSON = (try? JSONSerialization.data(withJSONObject: [pending.tex]))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "[\"\"]"
            webView.evaluateJavaScript("render(\(texJSON)[0], '\(css)', \(pending.fontSize))")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            if let pending { render(tex: pending.tex, color: pending.color, fontSize: pending.fontSize) }
        }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let value = message.body as? NSNumber else { return }
            let newHeight = CGFloat(value.doubleValue)
            if height.wrappedValue != newHeight { height.wrappedValue = newHeight }
        }
    }
}

/// Display-only: clicks pass through to the window (so it can be dragged) and focus stays in the input field.
private final class PassiveWebView: WKWebView {
    override var acceptsFirstResponder: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
