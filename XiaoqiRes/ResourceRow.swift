import SwiftUI

/// App Store 风格列表行：图标 + 名称 + 描述 + 右侧「获取」
struct ResourceRow: View {
    @Environment(AppStore.self) private var store
    let app: ResApp
    var onGet: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: store.iconURL(for: app))
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 13.5, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13.5, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(app.desc ?? app.system_req ?? "—")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button {
                onGet()
            } label: {
                Text(hasLink ? "获取" : "—")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(hasLink ? Color.accentColor : Color.secondary)
                    .padding(.horizontal, 14)
                    .frame(height: 28)
                    .background(
                        Capsule().fill(hasLink ? Color.accentColor.opacity(0.14) : Color(.tertiarySystemFill))
                    )
            }
            .buttonStyle(.borderless)
            .disabled(!hasLink)
        }
        .contentShape(Rectangle())
    }

    private var hasLink: Bool { store.downloadURL(for: app) != nil }
}
