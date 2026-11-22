import Foundation

struct SiteSettings: Codable, Hashable {
    var site_title: String?
    var search_placeholder: String?
    var web_title: String?
    var home_title: String?
    var apple_icon: String?

    init() {}
}

struct ResTag: Codable, Identifiable, Hashable {
    var id: Int
    var name: String
    var value: String
    var sort: Int?
}

struct ResApp: Codable, Identifiable, Hashable {
    var id: Int
    var name: String
    var tag: String?
    var tag_name: String?
    var desc: String?
    var icon: String?
    var screenshots: [String]?
    var download_url: String?
    var detail: String?
    var system_req: String?
    var is_top: Bool?
    var no_track: Bool?
    var sort: Int?
    var click_count: Int?
    var download_count: Int?
}

struct CarouselItem: Codable, Identifiable, Hashable {
    var id: Int
    var image: String?
    var link_type: String?
    var link_value: String?
    var resource_id: Int?
}

struct SiteData: Codable {
    var settings: SiteSettings
    var apps: [ResApp]
    var tags: [ResTag]
    var carousel: [CarouselItem]?
}

struct APIResponse: Codable {
    var code: Int
    var data: SiteData?
    var msg: String?
}
