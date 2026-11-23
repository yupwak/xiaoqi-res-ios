import SwiftUI

struct ContentView: View {
    @State private var store = AppStore()
    @State private var pushedApp: ResApp?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("资源", systemImage: "square.grid.2x2") }
                .tag(0)

            FavoritesView()
                .tabItem { Label("收藏", systemImage: "heart") }
                .tag(1)

            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
                .tag(2)
        }
        .environment(store)
        .task { await store.loadIfNeeded() }
        .onReceive(NotificationCenter.default.publisher(for: .pushOpenApp)) { note in
            guard let id = note.object as? Int else { return }
            selectedTab = 0
            if let app = store.app(withID: id) {
                pushedApp = app
            } else {
                Task {
                    if !store.hasLoaded { await store.load() }
                    if let app = store.app(withID: id) { pushedApp = app }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .pushOpenURL)) { note in
            guard let s = note.object as? String, let url = URL(string: s) else { return }
            UIApplication.shared.open(url)
        }
        .sheet(item: $pushedApp) { app in
            NavigationStack {
                DetailView(app: app)
            }
            .environment(store)
        }
    }
}
