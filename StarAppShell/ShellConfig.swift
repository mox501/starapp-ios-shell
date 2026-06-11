import Foundation
import UIKit

struct ShellConfig: Decodable {
    let name: String?
    let url: String
    let shellLanguage: String?
    let supportSplash: Bool?
    let splashTime: Int?
    let clearCookie: Bool?
    let supportPullToRefresh: Bool?
    let supportRightSlideGoBack: Bool?
    let supportScheme: Bool?
    let UserAgent: String?
    let statusBarColor: String?
    let statusBarTextColorMode: Int?

    static func load() -> ShellConfig {
        guard
            let url = Bundle.main.url(forResource: "config", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let config = try? JSONDecoder().decode(ShellConfig.self, from: data)
        else {
            return ShellConfig(
                name: nil,
                url: "https://www.baidu.com",
                shellLanguage: "zh",
                supportSplash: false,
                splashTime: 0,
                clearCookie: false,
                supportPullToRefresh: false,
                supportRightSlideGoBack: true,
                supportScheme: true,
                UserAgent: nil,
                statusBarColor: nil,
                statusBarTextColorMode: 0
            )
        }
        return config
    }

    var isEnglish: Bool {
        shellLanguage == "en"
    }

    var localizedNetworkError: String {
        isEnglish ? "Unable to load this page. Check your network and try again." : "页面无法打开，请检查网络后重试。"
    }
}

extension UIColor {
    convenience init?(hex: String?) {
        guard var raw = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        if raw.hasPrefix("#") { raw.removeFirst() }
        guard raw.count == 6, let value = Int(raw, radix: 16) else { return nil }
        self.init(
            red: CGFloat((value >> 16) & 0xff) / 255,
            green: CGFloat((value >> 8) & 0xff) / 255,
            blue: CGFloat(value & 0xff) / 255,
            alpha: 1
        )
    }
}
