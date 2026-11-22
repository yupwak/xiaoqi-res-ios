import SwiftUI
import UIKit

struct DetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let app: ResApp

    @State private var copied = false

    private var shots: [String] { app.screenshots ?? [] }
    private var detailText: String {
        let t = app.detail ?? ""
        return t.isEmpty ? (app.desc ?? "") : t
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
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

                block("信息") {
                    infoList
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
    }

    // MARK: - 顶部

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            RemoteImage(url: store.iconURL(for: app))
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(app.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let desc = app.desc, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                hstackTags
            }
            Spacer(minLength: 0)
        }
    }

    private var hstackTags: some View {
        HStack(spacing: 6) {
            if let tag = app.tag_name, !tag.isEmpty {
                tagChip(tag)
            }
            if let req = app.system_req, !req.isEmpty, req != app.desc {
                tagChip(req)
            }
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

    // MARK: - 截图（按原比例、宽度自适应）

    private var screenshots: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(Array(shots.enumerated()), id: \.offset) { _, path in
                    RemoteImage(url: store.imageURL(path))
                        .containerRelativeFrame(.horizontal) { length, _ in
                            max(160, length - 40)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color(.separator), lineWidth: 0.5)
                        )
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
    }

    // MARK: - 信息

    private var infoList: some View {
        VStack(spacing: 0) {
            infoRow("分类", app.tag_name ?? "—")
            Divider()
            infoRow("适配", app.system_req ?? "支持全系统")
            Divider()
            infoRow("下载次数", "\(app.download_count ?? 0)")
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func infoRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
    }

    // MARK: - 底部

    private var bottomBar: some View {
        VStack(spacing: 8) {
            Button {
                startDownload()
            } label: {
                Text(store.downloadURL(for: app) == nil ? "暂无下载地址" : "获取资源")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(store.downloadURL(for: app) == nil)

            HStack(spacing: 8) {
                Button {
                    copyLink()
                } label: {
                    Label(copied ? "已复制" : "复制链接", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                if let url = store.downloadURL(for: app) {
                    ShareLink(item: url) {
                        Label("分享", systemImage: "square.and.arrow.up")
                            .font(.system(size: 13))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private func startDownload() {
        guard let url = store.downloadURL(for: app) else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if app.no_track != true {
            Task { await APIClient.shared.trackDownload(appID: app.id) }
        }
        UIApplication.shared.open(url) { _ in }
    }

    private func copyLink() {
        guard let url = store.downloadURL(for: app) else { return }
        UIPasteboard.general.url = url
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { copied = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation { copied = false }
        }
    }
}
