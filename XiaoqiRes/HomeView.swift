import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(AppStore.self) private var store

    @State private var query = ""
    @State private var activeTag: String?
    @State private var detailApp: ResApp?

    private let columns = [GridItem(.adaptive(minimum: 152, maximum: 220), spacing: 12, alignment: .top)]

    private var results: [ResApp] {
        store.filtered(query: query, tag: activeTag)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        searchBar
                        tagBar
                        if !store.bannerItems.isEmpty && query.isEmpty {
                            banner
                        }
                        content
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .refreshable { await store.load() }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $detailApp) { app in
                DetailView(app: app)
                    .environment(store)
            }
        }
    }

    // MARK: - 头部

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(store.siteTitle)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(store.apps.count) 个资源")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Text("原生 iOS 客户端 · 小七资源库")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.35))
        }
    }

    // MARK: - 搜索

    private var searchBar: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))

            TextField("", text: $query, prompt: Text(store.searchPlaceholder).foregroundStyle(.white.opacity(0.32)))
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .glassPill()
        .animation(.easeOut(duration: 0.2), value: query.isEmpty)
    }

    // MARK: - 分类

    private var tagBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                tagChip(title: "全部", count: store.apps.count, selected: activeTag == nil) {
                    activeTag = nil
                }
                ForEach(store.sortedTags) { tag in
                    let count = store.apps.filter { $0.tag == tag.value }.count
                    tagChip(title: tag.name, count: count, selected: activeTag == tag.value) {
                        activeTag = (activeTag == tag.value) ? nil : tag.value
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func tagChip(title: String, count: Int, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 13, weight: selected ? .semibold : .medium))
                Text("\(count)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(selected ? Color.black.opacity(0.5) : Color.white.opacity(0.35))
            }
            .foregroundStyle(selected ? Color.black : Color.white.opacity(0.75))
            .padding(.horizontal, 13)
            .frame(height: 32)
            .background {
                if selected {
                    Capsule().fill(Theme.accent)
                }
            }
            .modifier(ChipGlass(selected: selected))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 轮播

    private var banner: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(store.bannerItems) { item in
                    Button {
                        handleBanner(item)
                    } label: {
                        RemoteImage(url: store.imageURL(item.image))
                            .frame(width: 300, height: 148)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(Theme.stroke, lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
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

    // MARK: - 内容

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.apps.isEmpty {
            loadingGrid
        } else if let err = store.loadError, store.apps.isEmpty {
            errorView(err)
        } else if results.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.white.opacity(0.2))
                Text(query.isEmpty ? "暂无资源" : "没有找到「\(query)」")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(results) { app in
                    Button {
                        detailApp = app
                    } label: {
                        AppCard(app: app)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var loadingGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 176)
                    .overlay(ProgressView().controlSize(.small).tint(.white.opacity(0.3)))
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.white.opacity(0.35))
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
            Button {
                Task { await store.load() }
            } label: {
                Text("重新加载")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 20)
                    .frame(height: 38)
            }
            .glassInteractiveCapsule()
            .tint(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
    }
}

private struct ChipGlass: ViewModifier {
    let selected: Bool

    func body(content: Content) -> some View {
        if selected {
            content
        } else {
            content
                .glassPill()
        }
    }
}
