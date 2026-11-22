import SwiftUI
import UIKit

struct FavoritesView: View {
    @Environment(AppStore.self) private var store
    @State private var detailApp: ResApp?

    private func startDownload(_ app: ResApp) {
        guard let url = store.downloadURL(for: app) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if app.no_track != true {
            Task { await APIClient.shared.trackDownload(appID: app.id) }
        }
        UIApplication.shared.open(url) { _ in }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.favoriteApps.isEmpty {
                    ContentUnavailableView(
                        "还没有收藏",
                        systemImage: "heart",
                        description: Text("在资源详情页点右上角的心形收藏")
                    )
                } else {
                    List {
                        Section {
                            ForEach(store.favoriteApps) { app in
                                Button {
                                    detailApp = app
                                } label: {
                                    ResourceRow(app: app) {
                                        detailApp = app
                                    }
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        store.toggleFavorite(app)
                                    } label: {
                                        Label("取消收藏", systemImage: "heart.slash")
                                    }
                                }
                            }
                        } header: {
                            Text("\(store.favoriteApps.count) 个资源")
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("收藏")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $detailApp) { app in
                NavigationStack {
                    DetailView(app: app)
                }
                .environment(store)
            }
        }
    }
}
