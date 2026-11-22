import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var cacheCleared = false

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("站点") {
                    LabeledContent("名称", value: store.siteTitle)
                    LabeledContent("资源数量", value: "\(store.apps.count)")
                    LabeledContent("分类数量", value: "\(store.tags.count)")
                    if let date = store.lastUpdated {
                        LabeledContent("最近刷新", value: date.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                Section("操作") {
                    Button {
                        Task { await store.load() }
                    } label: {
                        Label("刷新数据", systemImage: "arrow.clockwise")
                    }

                    Button {
                        store.clearCache()
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        withAnimation { cacheCleared = true }
                        Task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            withAnimation { cacheCleared = false }
                        }
                    } label: {
                        Label(cacheCleared ? "已清除" : "清除图片缓存", systemImage: "trash")
                    }

                    if let url = URL(string: "https://6778.top") {
                        Link(destination: url) {
                            Label("在浏览器打开官网", systemImage: "safari")
                        }
                    }
                }

                Section("关于") {
                    LabeledContent("版本", value: version)
                    LabeledContent("数据来源", value: "6778.top")
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("小七资源库由 6778.top 提供")
                        Text("开发者：Lxp")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
