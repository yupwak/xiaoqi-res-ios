import SwiftUI

@MainActor
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()

    private init() { cache.countLimit = 400 }

    func image(for url: URL) -> UIImage? { cache.object(forKey: url as NSURL) }
    func store(_ image: UIImage, for url: URL) { cache.setObject(image, forKey: url as NSURL) }
    func clear() { cache.removeAllObjects() }
}

/// 按原始比例显示的网络图片：不做裁剪、不拉伸，尺寸由父视图给多少用多少
struct RemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fit
    var placeholder: String = "photo"

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                ZStack {
                    Color(.tertiarySystemFill)
                    if failed {
                        Image(systemName: placeholder)
                            .font(.system(size: 18))
                            .foregroundStyle(.tertiary)
                    } else {
                        ProgressView().controlSize(.small)
                    }
                }
            }
        }
        .task(id: url) { await load() }
    }

    @MainActor private func load() async {
        guard let url else { failed = true; return }
        if let cached = ImageCache.shared.image(for: url) {
            image = cached
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let ui = UIImage(data: data) else { failed = true; return }
            ImageCache.shared.store(ui, for: url)
            image = ui
        } catch {
            failed = true
        }
    }
}
