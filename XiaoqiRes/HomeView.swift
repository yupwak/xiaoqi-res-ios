import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(AppStore.self) private var store

    @State private var query = ""
    @State private var tagFilter: String?
    @State private var detailApp: ResApp?

    private var results: [ResApp] {
        store.filtered(query: query, tag: tagFilter)
    }

    private var headerTitle: String {
        let t = store.settings.home_title ?? store.settings.site_title ?? "Resource"
        return t.isEmpty ? "Resource" : t
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if !store.bannerItems.isEmpty && query.isEmpty && tagFilter == nil {
                        banner
                    }

                    if store.isLoading && store.apps.isEmpty {
                        loadingRows
                    } else if let err = store.loadError, store.apps.isEmpty {
                        errorView(err)
                    } else if results.isEmpty {
                        emptyView
                    } else {
                        ForEach(results) { app in
                            ResourceRow(app: app) {
                                detailApp = app
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .onTapGesture { detailApp = app }
                        }
                    }
                }
                .padding(.bottom, 28)
            }
            .background(Color(.systemBackground))
            .navigationTitle(headerTitle)
            .navigationBarTitleDisplayMode(.large)
            .safeAreaInset(edge: .top, spacing: 0) {
                searchBar
            }
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

    // MARK: - 独立搜索条

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("", text: $query, prompt: Text(store.searchPlaceholder).foregroundStyle(.secondary))
                .font(.system(size: 16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 36)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 轮播

    private var banner: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(store.bannerItems) { item in
                    Button {
                        handleBanner(item)
                    } label: {
                        RemoteImage(url: store.imageURL(item.image))
                            .containerRelativeFrame(.horizontal) { length, _ in
                                max(200, length - 32)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color(.separator), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, 16)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private func handleBanner(_ item: CarouselItem) {
        if let rid = item.resource_id, rid > 0, let app = store.app(withID: rid) {
            detailApp = app
            return
        }
        if let v = item.link_value, let url = URL(string: v), v.hasPrefix("http") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - 筛选

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

    // MARK: - 状态

    private var loadingRows: some View {
        ForEach(0..<6, id: \.self) { _ in
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 13.5, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 60, height: 60)
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(width: 110, height: 12)
                    RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(width: 170, height: 10)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
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
        .padding(.vertical, 48)
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
        .padding(.vertical, 48)
    }
}
