import UIKit
import WebKit

final class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UIGestureRecognizerDelegate {
    private let config = ShellConfig.load()
    private var webView: WKWebView!
    private var splashView: UIView?
    private var refreshControl: UIRefreshControl?
    private var edgeBackGesture: UIScreenEdgePanGestureRecognizer?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        config.usesDarkStatusBarText ? .darkContent : .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureStatusBar()
        configureWebView()
        configureSplash()
        loadStartURL()
    }

    private func configureStatusBar() {
        view.backgroundColor = config.effectiveStatusBarColor
    }

    private func configureWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = config.supportRightSlideGoBack != false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if let userAgent = config.UserAgent, !userAgent.isEmpty {
            webView.customUserAgent = userAgent
        }
        if config.clearCookie == true {
            WKWebsiteDataStore.default().removeData(
                ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                modifiedSince: Date(timeIntervalSince1970: 0),
                completionHandler: {}
            )
        }
        if config.supportPullToRefresh == true {
            let refresh = UIRefreshControl()
            refresh.addTarget(self, action: #selector(reloadPage), for: .valueChanged)
            webView.scrollView.refreshControl = refresh
            refreshControl = refresh
        }
        if config.supportRightSlideGoBack != false {
            let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgeBack(_:)))
            gesture.edges = .left
            gesture.delegate = self
            view.addGestureRecognizer(gesture)
            edgeBackGesture = gesture
        }
    }

    private func configureSplash() {
        guard config.supportSplash == true, let image = UIImage(named: "splash") else { return }
        let holder = UIView(frame: view.bounds)
        holder.backgroundColor = .white
        holder.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        holder.addSubview(imageView)
        view.addSubview(holder)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: holder.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: holder.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: holder.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: holder.bottomAnchor)
        ])
        splashView = holder
    }

    private func loadStartURL() {
        guard let url = URL(string: config.url) else {
            showError()
            return
        }
        webView.load(URLRequest(url: url))
    }

    @objc private func reloadPage() {
        webView.reload()
    }

    @objc private func handleEdgeBack(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard gesture.state == .ended, webView.canGoBack else { return }
        webView.goBack()
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === edgeBackGesture {
            return webView.canGoBack
        }
        return true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        refreshControl?.endRefreshing()
        let delay = max(0, config.splashTime ?? 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay * 1000)) { [weak self] in
            UIView.animate(withDuration: 0.18, animations: {
                self?.splashView?.alpha = 0
            }, completion: { _ in
                self?.splashView?.removeFromSuperview()
                self?.splashView = nil
            })
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        refreshControl?.endRefreshing()
        showError()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        refreshControl?.endRefreshing()
        showError()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        let scheme = url.scheme?.lowercased() ?? ""
        if ["http", "https", "about"].contains(scheme) {
            decisionHandler(.allow)
            return
        }
        if config.supportScheme != false, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        decisionHandler(.cancel)
    }

    private func showError() {
        let label = UILabel()
        label.text = config.localizedNetworkError
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.backgroundColor = .systemBackground
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 28),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -28)
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            container.removeFromSuperview()
        }
    }
}
