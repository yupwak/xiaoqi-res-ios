import UIKit
import UserNotifications

struct PushMessage: Decodable {
    let id: String
    let title: String
    let body: String
    let app_id: Int?
    let url: String?
    let ts: Int

    enum CodingKeys: String, CodingKey { case id, title, body, app_id, url, ts }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        title = (try? c.decode(String.self, forKey: .title)) ?? "小七资源库"
        body = (try? c.decode(String.self, forKey: .body)) ?? ""
        app_id = try? c.decode(Int.self, forKey: .app_id)
        url = try? c.decode(String.self, forKey: .url)
        ts = (try? c.decode(Int.self, forKey: .ts)) ?? 0
    }
}

final class PushRouter {
    static let shared = PushRouter()

    var pendingAppID: Int?
    var pendingURL: String?

    func route(appID: Int?, url: String?) {
        if let appID, appID > 0 {
            pendingAppID = appID
            NotificationCenter.default.post(name: .pushOpenApp, object: appID)
        } else if let url, !url.isEmpty, let u = URL(string: url), u.scheme?.hasPrefix("http") == true {
            pendingURL = url
            NotificationCenter.default.post(name: .pushOpenURL, object: url)
        } else {
            let home = "https://6778.top"
            pendingURL = home
            NotificationCenter.default.post(name: .pushOpenURL, object: home)
        }
    }

    func takePending() -> (appID: Int?, url: String?) {
        let r = (pendingAppID, pendingURL)
        pendingAppID = nil
        pendingURL = nil
        return r
    }
}

final class PushManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PushManager()

    private(set) var token: String?

    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted { UIApplication.shared.registerForRemoteNotifications() }
            }
        }
        if let saved = UserDefaults.standard.string(forKey: "push.token") {
            token = saved
        }
    }

    func didRegister(_ data: Data) {
        let hex = data.map { String(format: "%02x", $0) }.joined()
        token = hex
        UserDefaults.standard.set(hex, forKey: "push.token")
        Task { await APIClient.shared.registerDevice(token: hex) }
    }

    func didFail(_ error: Error) {
        NSLog("push register failed: %@", error.localizedDescription)
    }

    // 前台也显示横幅
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        var appID: Int?
        var url: String?
        if let v = info["app_id"] as? Int { appID = v }
        if let s = info["app_id"] as? String { appID = Int(s) }
        if let u = info["url"] as? String, !u.isEmpty { url = u }
        DispatchQueue.main.async {
            PushRouter.shared.route(appID: appID, url: url)
        }
        UNUserNotificationCenter.current().setBadgeCount(0)
        completionHandler()
    }

    /// 没有 APNs 时的兜底：前台拉取收件箱并本地弹通知
    func pullInbox() async {
        guard let token, let messages = await APIClient.shared.pullMessages(token: token), !messages.isEmpty else { return }
        let key = "push.lastTs"
        let lastTs = UserDefaults.standard.integer(forKey: key)
        var newest = lastTs
        for m in messages where m.ts > lastTs {
            fire(m)
            if m.ts > newest { newest = m.ts }
        }
        if newest > lastTs { UserDefaults.standard.set(newest, forKey: key) }
    }

    private func fire(_ message: PushMessage) {
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default
        content.badge = 1
        var info: [String: Any] = [:]
        if let id = message.app_id { info["app_id"] = id }
        if let u = message.url, !u.isEmpty { info["url"] = u }
        content.userInfo = info
        let request = UNNotificationRequest(identifier: "inbox-" + message.id,
                                            content: content,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }
}

extension Notification.Name {
    static let pushOpenApp = Notification.Name("xq.push.open.app")
    static let pushOpenURL = Notification.Name("xq.push.open.url")
}
