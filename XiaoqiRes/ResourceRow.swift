import SwiftUI

/// 列表行（收藏页用）：图标 + 名称 + 描述
struct ResourceRow: View {
    @Environment(AppStore.self) private var store
    let app: ResApp

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: store.iconURL(for: app))
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 15.5, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(app.desc ?? app.system_req ?? "—")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
