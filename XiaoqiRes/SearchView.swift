import SwiftUI

struct SearchView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var detailApp: ResApp?

    private var results: [ResApp] {
        store.filtered(query: query, tag: nil)
    }

    var body: some View {
        VStack(spacing: 0) {
                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    hint
                } else if results.isEmpty {
                    empty
                } else {
                    List {
                        ForEach(results) { app in
                            Button {
                                detailApp = app
                            } label: {
                                ResourceRow(app: app) {
                                    detailApp = app
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollDismissesKeyboard(.immediately)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") { dismiss() }
                }
            }
            .sheet(item: $detailApp) { app in
                NavigationStack {
                    DetailView(app: app)
                }
                .environment(store)
            }
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text(store.searchPlaceholder)
            )
    }

    private var hint: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text("搜索资源名称或介绍")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 80)
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.circle")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text("没有匹配「\(query)」的结果")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 80)
    }
}
