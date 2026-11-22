import SwiftUI

struct AppCard: View {
    @Environment(AppStore.self) private var store
    let app: ResApp

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 8) {
                RemoteImage(url: store.iconURL(for: app))
                    .frame(width: 54, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                    )

                Spacer(minLength: 0)

                if app.is_top == true {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange.opacity(0.9))
                        .padding(5)
                        .background(Circle().fill(.white.opacity(0.08)))
                }
            }

            Text(app.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(app.desc ?? app.system_req ?? " ")
                .font(.system(size: 11.5))
                .foregroundStyle(.white.opacity(0.42))
                .lineLimit(1)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                if let tagName = app.tag_name, !tagName.isEmpty {
                    Text(tagName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.white.opacity(0.08)))
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.down.to.line")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                Text("\(app.download_count ?? 0)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.32))
            }
        }
        .padding(12)
        .frame(height: 178, alignment: .topLeading)
        .glassCard(20)
    }
}
