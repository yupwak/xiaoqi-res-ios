import SwiftUI

/// 首页网格单元：图标 + 名称，无卡片底板
struct ResourceCell: View {
    @Environment(AppStore.self) private var store
    let app: ResApp

    var body: some View {
        VStack(spacing: 8) {
            RemoteImage(url: store.iconURL(for: app))
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )

            Text(app.name)
                .font(.system(size: 12.5))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}
