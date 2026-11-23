import Foundation
import UIKit

enum APIError: LocalizedError {
    case network(String)
    case decoding(String)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .network(let m): return "网络异常：\(m)"
        case .decoding(let m): return "数据解析失败：\(m)"
        case .server(let m): return m
        }
    }
}

struct APIClient {
    static let shared = APIClient()

    private let base = URL(string: "https://6778.top/")!
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 20
        c.timeoutIntervalForResource = 40
        c.waitsForConnectivity = true
        c.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: c)
    }()

    func url(for path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http://") || path.hasPrefix("https://") { return URL(string: path) }
        let p = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: p.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? p, relativeTo: base)
    }

    private func post(_ fields: [String: String]) async throws -> Data {
        var req = URLRequest(url: base.appendingPathComponent("api.php"))
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setValue("XiaoqiRes/1.0 (iOS; Native)", forHTTPHeaderField: "User-Agent")
        var comps = URLComponents()
        comps.queryItems = fields.map { URLQueryItem(name: $0.key, value: $0.value) }
        req.httpBody = (comps.percentEncodedQuery ?? "").data(using: .utf8)

        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                throw APIError.server("无效响应")
            }
            guard (200..<300).contains(http.statusCode) else {
                throw APIError.server("服务器返回 HTTP \(http.statusCode)")
            }
            return data
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.network(error.localizedDescription)
        }
    }

    func getData() async throws -> SiteData {
        let data = try await post(["source": "front", "action": "get_data"])
        do {
            let res = try JSONDecoder().decode(APIResponse.self, from: data)
            guard res.code == 0, let d = res.data else {
                throw APIError.server(res.msg?.isEmpty == false ? (res.msg ?? "接口返回异常") : "接口返回异常")
            }
            return d
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    func trackVisit() async {
        _ = try? await post(["source": "front", "action": "track_visit"])
    }

    func trackDownload(appID: Int) async {
        _ = try? await post(["source": "front", "action": "track_download", "app_id": String(appID)])
        _ = try? await post(["source": "front", "action": "add_download", "rid": String(appID)])
    }

    // MARK: - 推送

    func registerDevice(token: String) async {
        var fields = [
            "source": "front",
            "action": "register_device",
            "token": token,
            "platform": "ios",
            "model": UIDevice.current.model,
            "name": UIDevice.current.name,
            "version": (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "",
            "bundle": (Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String) ?? ""
        ]
        fields["nonce"] = UUID().uuidString
        _ = try? await post(fields)
    }

    func pullMessages(token: String) async -> [PushMessage]? {
        guard let data = try? await post([
            "source": "front",
            "action": "pull_messages",
            "token": token
        ]) else { return nil }
        struct Envelope: Decodable {
            struct Payload: Decodable { let messages: [PushMessage] }
            let code: Int
            let data: Payload?
        }
        guard let env = try? JSONDecoder().decode(Envelope.self, from: data), let payload = env.data else { return nil }
        return payload.messages
    }

    func getSponsors() async throws -> [Sponsor] {
        let data = try await post(["source": "front", "action": "get_sponsors"])
        do {
            let env = try JSONDecoder().decode(SponsorEnvelope.self, from: data)
            guard env.code == 0, let payload = env.data else {
                throw APIError.server("赞助名单读取失败")
            }
            return payload.sponsors.sorted {
                if $0.amount == $1.amount { return ($0.ts ?? 0) > ($1.ts ?? 0) }
                return $0.amount > $1.amount
            }
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }
}
