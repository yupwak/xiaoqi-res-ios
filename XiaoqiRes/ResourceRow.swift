import SwiftUI

/// 一行一个应用：图标 + 名称 + 描述（无卡片底板、不显示次数）
struct ResourceRow: View {
    @Environment(AppStore.self) private var store
    let app: ResApp

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: store.iconURL(for: app))
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
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

            Spacer(minLength: 4)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
