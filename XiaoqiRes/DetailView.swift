import SwiftUI
import UIKit

struct DetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let app: ResApp

    @State private var toast: String?

    private var shots: [String] { app.screenshots ?? [] }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    topBar
                    headerBlock
                    actionRow
                    screenshotsSection
                    detailSection
                    infoSection
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
            }
            .scrollIndicators(.hidden)

            if let toast {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 40)
                        .glassPill()
                        .padding(.bottom, 110)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            downloadBar
        }
        .presentationDetents([.large, .medium])
        .presentationDragIndicator(.visible)
        .animation(.easeOut(duration: 0.25), value: toast)
    }

    // MARK: - 顶部操作

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .glassInteractiveCapsule()
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                store.toggleFavorite(app)
                flash(store.isFavorite(app) ? "已加入收藏" : "已取消收藏")
            } label: {
                Image(systemName: store.isFavorite(app) ? "heart.fill" : "heart")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(store.isFavorite(app) ? Theme.accent : Color.white.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .glassInteractiveCapsule()
            }
            .buttonStyle(.plain)

            if let url = store.downloadURL(for: app) {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .glassInteractiveCapsule()
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 头图信息

    private var headerBlock: some View {
        HStack(alignment: .center, spacing: 14) {
            RemoteImage(url: store.iconURL(for: app))
                .frame(width: 78, height: 78)
                .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 19, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(app.name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let tagName = app.tag_name {
                        pill(tagName)
                    }
                    if let req = app.system_req, !req.isEmpty {
                        pill(req)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .medium))
            .foregroundStyle(.white.opacity(0.65))
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(Capsule().fill(.white.opacity(0.09)))
    }

    // MARK: - 统计

    private var actionRow: some View {
        HStack(spacing: 10) {
            statBox(title: "下载", value: "\(app.download_count ?? 0)")
            statBox(title: "浏览", value: "\(app.click_count ?? 0)")
            statBox(title: "分类", value: app.tag_name ?? "—")
        }
    }

    private func statBox(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.system(size: 10.5))
                .foregroundStyle(.white.opacity(0.38))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .glassCard(16)
    }

    // MARK: - 截图

    @ViewBuilder
    private var screenshotsSection: some View {
        if !shots.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("预览")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(shots.enumerated()), id: \.offset) { _, path in
                            RemoteImage(url: store.imageURL(path))
                                .frame(width: 220, height: 400)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(Theme.stroke, lineWidth: 0.8)
                                )
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    // MARK: - 介绍

    @ViewBuilder
    private var detailSection: some View {
        let text = (app.detail?.isEmpty == false ? app.detail! : (app.desc ?? ""))
        if !text.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("介绍")
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("信息")
            VStack(spacing: 0) {
                infoRow("资源 ID", "\(app.id)")
                Divider().overlay(Color.white.opacity(0.06))
                infoRow("适配", app.system_req ?? "支持全系统")
                Divider().overlay(Color.white.opacity(0.06))
                infoRow("来源", "6778.top")
            }
            .padding(.horizontal, 14)
            .glassCard(16)
        }
    }

    private func infoRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.42))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(height: 44)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.85))
    }

    // MARK: - 底部下载

    private var downloadBar: some View {
        VStack(spacing: 0) {
            Button {
                startDownload()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text(store.downloadURL(for: app) == nil ? "暂无下载地址" : "立即获取")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(store.downloadURL(for: app) == nil ? Color.white.opacity(0.4) : Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background {
                    if store.downloadURL(for: app) != nil {
                        Capsule().fill(Theme.accent)
                    } else {
                        Capsule().fill(Color.white.opacity(0.08))
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(store.downloadURL(for: app) == nil)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 6)
        }
        .background(.ultraThinMaterial)
    }

    private func startDownload() {
        guard let url = store.downloadURL(for: app) else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if app.no_track != true {
            Task { await APIClient.shared.trackDownload(appID: app.id) }
        }
        UIApplication.shared.open(url) { _ in }
        flash("已跳转下载页面")
    }

    private func flash(_ text: String) {
        toast = text
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            if toast == text { toast = nil }
        }
    }
}
