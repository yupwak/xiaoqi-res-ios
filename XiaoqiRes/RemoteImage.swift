import SwiftUI

@MainActor
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()

    private init() { cache.countLimit = 300 }

    func image(for url: URL) -> UIImage? { cache.object(forKey: url as NSURL) }
    func store(_ image: UIImage, for url: URL) { cache.setObject(image, forKey: url as NSURL) }
    func clear() { cache.removeAllObjects() }
}

struct RemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    var placeholderIcon: String = "square.stack.3d.up"

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Rectangle().fill(Color.white.opacity(0.05))
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else if failed {
                    Image(systemName: placeholderIcon)
                        .font(.system(size: min(geo.size.width, geo.size.height) * 0.32, weight: .light))
                        .foregroundStyle(.white.opacity(0.22))
                } else {
                    ProgressView().controlSize(.small).tint(.white.opacity(0.35))
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
            guard let ui = UIImage(data: data) else {
                failed = true
                return
            }
            ImageCache.shared.store(ui, for: url)
            image = ui
        } catch {
            failed = true
        }
    }
}
