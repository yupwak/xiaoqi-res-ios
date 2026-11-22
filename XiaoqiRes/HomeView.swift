import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store

    @State private var query = ""
    @State private var tagFilter: String?
    @State private var detailApp: ResApp?

    private var results: [ResApp] {
        store.filtered(query: query, tag: tagFilter)
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
                    ForEach(results) { app in
                        Button {
                            detailApp = app
                        } label: {
                            ResourceRow(app: app)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                    }
                }
            }
            .listStyle(.plain)
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
        ForEach(0..<6, id: \.self) { _ in
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(width: 110, height: 12)
                    RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(width: 170, height: 10)
                }
                Spacer()
            }
            .padding(.vertical, 6)
            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
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
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
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
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
