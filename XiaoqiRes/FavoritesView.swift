import SwiftUI

struct FavoritesView: View {
    @Environment(AppStore.self) private var store
    @State private var detailApp: ResApp?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                if store.favoriteApps.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(.white.opacity(0.18))
                        Text("还没有收藏")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                        Text("在资源详情页点右上角 ♥ 收藏")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("我的收藏")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.top, 8)
                            Text("\(store.favoriteApps.count) 个资源")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.35))

                            ForEach(store.favoriteApps) { app in
                                Button {
                                    detailApp = app
                                } label: {
                                    row(app)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        store.toggleFavorite(app)
                                    } label: {
                                        Label("取消收藏", systemImage: "heart.slash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 30)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $detailApp) { app in
                DetailView(app: app).environment(store)
            }
        }
    }

    private func row(_ app: ResApp) -> some View {
        HStack(spacing: 12) {
            RemoteImage(url: store.iconURL(for: app))
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.8)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(app.desc ?? app.system_req ?? "")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.22))
        }
        .padding(12)
        .glassCard(18)
    }
}
