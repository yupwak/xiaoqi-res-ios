import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store

    @State private var query = ""
    @State private var tagFilter: String?
    @State private var detailApp: ResApp?

    private let columns = [GridItem(.adaptive(minimum: 96, maximum: 140), spacing: 16, alignment: .top)]

    private var results: [ResApp] {
        store.filtered(query: query, tag: tagFilter)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if store.isLoading && store.apps.isEmpty {
                        loadingGrid
                    } else if let err = store.loadError, store.apps.isEmpty {
                        errorView(err)
                    } else if results.isEmpty {
                        emptyView
                    } else {
                        LazyVGrid(columns: columns, spacing: 22) {
                            ForEach(results) { app in
                                Button {
                                    detailApp = app
                                } label: {
                                    ResourceCell(app: app)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text("数据来自 6778.top")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
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

    private var loadingGrid: some View {
        LazyVGrid(columns: columns, spacing: 22) {
            ForEach(0..<9, id: \.self) { _ in
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 64, height: 64)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 48, height: 10)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func errorView(_ message: String) -> some View {
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
        .padding(.top, 80)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(query.isEmpty ? "暂无资源" : "没有匹配「\(query)」的结果")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}
