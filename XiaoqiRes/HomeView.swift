import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store

    @State private var query = ""
    @State private var tagFilter: String?
    @State private var detailApp: ResApp?

    private var results: [ResApp] {
        store.filtered(query: query, tag: tagFilter)
    }

    private var sectionTitle: String {
        if let tagFilter, let t = store.sortedTags.first(where: { $0.value == tagFilter }) {
            return t.name
        }
        return "全部资源"
    }

    var body: some View {
        NavigationStack {
            List {
                if store.isLoading && store.apps.isEmpty {
                    loadingRows
                } else if let err = store.loadError, store.apps.isEmpty {
                    errorRow(err)
                } else if results.isEmpty {
                    emptyRow
                } else {
                    Section {
                        ForEach(results) { app in
                            Button {
                                detailApp = app
                            } label: {
                                ResourceRow(app: app)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        HStack {
                            Text(sectionTitle)
                            Spacer()
                            Text("\(results.count)")
                                .monospacedDigit()
                        }
                    } footer: {
                        if let date = store.lastUpdated {
                            Text("更新于 \(date.formatted(date: .abbreviated, time: .shortened))")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(store.siteTitle)
            .searchable(text: $query, prompt: Text(store.searchPlaceholder))
            .refreshable { await store.load() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterMenu
                }
            }
            .sheet(item: $detailApp) { app in
                NavigationStack {
                    DetailView(app: app)
                }
                .environment(store)
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            Button {
                tagFilter = nil
            } label: {
                Label("全部", systemImage: tagFilter == nil ? "checkmark" : "square.grid.2x2")
            }
            if !store.sortedTags.isEmpty { Divider() }
            ForEach(store.sortedTags) { tag in
                Button {
                    tagFilter = tag.value
                } label: {
                    Label(tag.name, systemImage: tagFilter == tag.value ? "checkmark" : "tag")
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }

    private var loadingRows: some View {
        ForEach(0..<5, id: \.self) { _ in
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(width: 120, height: 12)
                    RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(width: 180, height: 10)
                }
                Spacer()
            }
            .padding(.vertical, 6)
        }
    }

    private func errorRow(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("重新加载") {
                Task { await store.load() }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .listRowBackground(Color.clear)
    }

    private var emptyRow: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(query.isEmpty ? "暂无资源" : "没有匹配「\(query)」的结果")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .listRowBackground(Color.clear)
    }
}
