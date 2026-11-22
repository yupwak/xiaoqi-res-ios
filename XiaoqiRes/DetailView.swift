import SwiftUI
import UIKit

struct DetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let app: ResApp

    private var shots: [String] { app.screenshots ?? [] }
    private var detailText: String {
        let t = app.detail ?? ""
        return t.isEmpty ? (app.desc ?? "") : t
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if !detailText.isEmpty {
                    block("介绍") {
                        Text(detailText)
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if !shots.isEmpty {
                    block("预览") {
                        screenshots
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("关闭") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleFavorite(app)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: store.isFavorite(app) ? "heart.fill" : "heart")
                }
            }
        }
    }

    // MARK: - 顶部

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            RemoteImage(url: store.iconURL(for: app))
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(app.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    if let tag = app.tag_name, !tag.isEmpty {
                        tagChip(tag)
                    }
                    if let req = app.system_req, !req.isEmpty, req != app.desc {
                        tagChip(req)
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func tagChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color(.tertiarySystemFill)))
    }

    // MARK: - 段落

    private func block<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    // MARK: - 预览（按原比例、宽度自适应）

    private var screenshots: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(Array(shots.enumerated()), id: \.offset) { _, path in
                    RemoteImage(url: store.imageURL(path))
                        .containerRelativeFrame(.horizontal) { length, _ in
                            max(160, length - 40)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color(.separator), lineWidth: 0.5)
                        )
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
    }

    // MARK: - 底部

    private var bottomBar: some View {
        HStack {
            Spacer()
            Button {
                startDownload()
            } label: {
                Text(store.downloadURL(for: app) == nil ? "暂无下载地址" : "获取")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(minWidth: 132, minHeight: 42)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .disabled(store.downloadURL(for: app) == nil)
            Spacer()
        }
        .padding(.vertical, 6)
        .background(.bar)
    }

    // MARK: - 动作

    private func startDownload() {
        guard let url = store.downloadURL(for: app) else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if app.no_track != true {
            Task { await APIClient.shared.trackDownload(appID: app.id) }
        }
        UIApplication.shared.open(url) { _ in }
    }
}
