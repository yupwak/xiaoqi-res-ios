import SwiftUI

struct ContentView: View {
    @State private var store = AppStore()

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("资源", systemImage: "square.grid.2x2") }

            FavoritesView()
                .tabItem { Label("收藏", systemImage: "heart") }

            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
        .environment(store)
        .task { await store.loadIfNeeded() }
    }
}
