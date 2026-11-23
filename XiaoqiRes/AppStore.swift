import SwiftUI
import Observation

@MainActor
@Observable
final class AppStore {
    var settings = SiteSettings()
    var apps: [ResApp] = []
    var tags: [ResTag] = []
    var carousel: [CarouselItem] = []
    var sponsors: [Sponsor] = []

    var isLoading = false
    var hasLoaded = false
    var loadError: String?
    var lastUpdated: Date?

    var favorites: Set<Int> = Set(UserDefaults.standard.array(forKey: "xq.favorites") as? [Int] ?? [])

    var siteTitle: String {
        settings.web_title ?? settings.site_title ?? "小七资源库"
    }
    var searchPlaceholder: String {
        settings.search_placeholder ?? "搜索资源..."
    }
    var sortedTags: [ResTag] {
        tags.sorted { ($0.sort ?? 0) < ($1.sort ?? 1) }
    }
    var bannerItems: [CarouselItem] { carousel }
    var sponsorTotal: Double {
        sponsors.reduce(0) { $0 + $1.amount }
    }
    var totalDownloads: Int {
        apps.reduce(0) { $0 + ($1.download_count ?? 0) }
    }

    func filtered(query: String, tag: String?) -> [ResApp] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return apps.filter { app in
            if let tag, app.tag != tag { return false }
            if q.isEmpty { return true }
            let haystack = [app.name, app.desc ?? "", app.detail ?? "", app.tag_name ?? "", app.system_req ?? ""]
                .joined(separator: " ")
                .lowercased()
            return haystack.contains(q)
        }
    }

    func loadIfNeeded() async {
        guard !hasLoaded, !isLoading else { return }
        await load()
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let d = try await APIClient.shared.getData()
            settings = d.settings
            tags = d.tags
            carousel = d.carousel ?? []
            sponsors = (try? await APIClient.shared.getSponsors()) ?? sponsors
            apps = d.apps.sorted { a, b in
                let ta = a.is_top ?? false, tb = b.is_top ?? false
                if ta != tb { return ta }
                let sa = a.sort ?? 0, sb = b.sort ?? 0
                if sa != sb { return sa < sb }
                return a.id < b.id
            }
            loadError = nil
            hasLoaded = true
            lastUpdated = Date()
        } catch {
            loadError = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        Task { await APIClient.shared.trackVisit() }
    }

    func iconURL(for app: ResApp) -> URL? { APIClient.shared.url(for: app.icon) }
    func imageURL(_ path: String?) -> URL? { APIClient.shared.url(for: path) }
    func downloadURL(for app: ResApp) -> URL? { APIClient.shared.url(for: app.download_url) }

    func isFavorite(_ app: ResApp) -> Bool { favorites.contains(app.id) }

    func toggleFavorite(_ app: ResApp) {
        if favorites.contains(app.id) { favorites.remove(app.id) } else { favorites.insert(app.id) }
        UserDefaults.standard.set(Array(favorites), forKey: "xq.favorites")
    }

    func app(withID id: Int) -> ResApp? { apps.first { $0.id == id } }

    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        ImageCache.shared.clear()
    }
}
