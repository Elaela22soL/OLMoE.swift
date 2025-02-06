import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: UIViewRepresentableContext<WebView>) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<WebView>) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate

        /// Intercepts navigation actions in the WKWebView.
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            print("Navigation action type: \(navigationAction.navigationType)")
            
            // Log the destination URL if available.
            if let url = navigationAction.request.url {
                print("Destination URL: \(url.absoluteString)")
            }

            // Check if the navigation action is triggered by a link click or form submission,
            // and the URL contains "http"
            if let url = navigationAction.request.url,
               url.absoluteString.contains("http") ||
               navigationAction.navigationType == .linkActivated || navigationAction.navigationType == .formSubmitted,
               !url.absoluteString.contains("https://playground.allenai.org") {
                // Open the URL in Safari.
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                // Cancel the navigation within the web view.
                decisionHandler(.cancel)
                return
            }
            
            // Allow all other types of navigation.
            decisionHandler(.allow)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

struct WebViewWithBanner: View {
    let url: URL
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("⚠️ Running on AI2's servers - not on your device")
                    .font(.footnote)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.black)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color("Warning"))
            .foregroundColor(.black)

            WebView(url: url)
        }
    }
}
