import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var showClearDone = false

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("设置")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.top, 8)

                        group("数据") {
                            infoRow("资源数量", "\(store.apps.count)")
                            divider
                            infoRow("分类数量", "\(store.tags.count)")
                            divider
                            infoRow("收藏数量", "\(store.favorites.count)")
                            divider
                            infoRow("最近刷新", store.lastUpdated.map { Self.formatter.string(from: $0) } ?? "—")
                        }

                        group("操作") {
                            Button {
                                Task { await store.load() }
                            } label: {
                                actionRow("刷新全部数据", icon: "arrow.clockwise", tint: Theme.accent)
                            }
                            .buttonStyle(.plain)
                            divider
                            Button {
                                store.clearCache()
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation { showClearDone = true }
                                Task {
                                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                                    withAnimation { showClearDone = false }
                                }
                            } label: {
                                actionRow(showClearDone ? "缓存已清理" : "清理图片缓存", icon: "trash", tint: .orange)
                            }
                            .buttonStyle(.plain)
                            divider
                            Button {
                                if let url = URL(string: "https://6778.top") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                actionRow("在浏览器打开官网", icon: "safari", tint: .blue)
                            }
                            .buttonStyle(.plain)
                        }

                        group("关于") {
                            infoRow("应用名称", "小七资源库")
                            divider
                            infoRow("版本", version)
                            divider
                            infoRow("构建", "原生 iOS 26 · SwiftUI")
                            divider
                            infoRow("数据来源", "6778.top")
                        }

                        Text("本应用为 6778.top 的非官方原生客户端，所有资源信息由站点接口提供。")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.25))
                            .padding(.horizontal, 4)

                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 18)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm"
        return f
    }()

    private var divider: some View {
        Divider().overlay(Color.white.opacity(0.06))
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
                .padding(.leading, 4)
            VStack(spacing: 0) { content() }
                .padding(.horizontal, 14)
                .glassCard(18)
        }
    }

    private func infoRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 13.5))
                .foregroundStyle(.white.opacity(0.55))
            Spacer()
            Text(value)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
        }
        .frame(height: 44)
    }

    private func actionRow(_ title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 22)
            Text(title)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.2))
        }
        .frame(height: 46)
        .contentShape(Rectangle())
    }
}
