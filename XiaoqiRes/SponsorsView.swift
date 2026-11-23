import SwiftUI
import UIKit

struct SponsorsView: View {
    @Environment(AppStore.self) private var store
    @State private var loaded = false

    private let zanURL = URL(string: "https://6778.top/zan")!

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        UIApplication.shared.open(zanURL)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(Color.orange.gradient)
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 34, height: 34)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("赞助小七资源库")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.primary)
                                Text("前往 6778.top/zan")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section {
                    if store.sponsors.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "crown")
                                .font(.title2)
                                .foregroundStyle(.tertiary)
                            Text("还没有赞助名单")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(Array(store.sponsors.enumerated()), id: \.element.id) { index, sponsor in
                            row(index: index, sponsor: sponsor)
                        }
                    }
                } header: {
                    HStack {
                        Text("赞助名单")
                        Spacer()
                        if !store.sponsors.isEmpty {
                            Text("\(store.sponsors.count) 人 · ¥\(Self.money(store.sponsorTotal))")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("赞助")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await reload() }
            .task {
                if !loaded {
                    loaded = true
                    await reload()
                }
            }
        }
    }

    private func row(index: Int, sponsor: Sponsor) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(medalColor(index))
                .frame(width: 20, alignment: .center)

            avatar(sponsor)

            VStack(alignment: .leading, spacing: 2) {
                Text(sponsor.name)
                    .font(.system(size: 15.5, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let note = sponsor.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Text("¥" + Self.money(sponsor.amount))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.orange)
                .monospacedDigit()
        }
        .padding(.vertical, 3)
    }

    @ViewBuilder
    private func avatar(_ sponsor: Sponsor) -> some View {
        let url = store.imageURL(sponsor.avatar)
        if let url {
            RemoteImage(url: url)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Color(.separator), lineWidth: 0.5))
        } else {
            ZStack {
                Circle().fill(Color(.secondarySystemFill))
                Text(String(sponsor.name.prefix(1)))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40, height: 40)
        }
    }

    private func medalColor(_ index: Int) -> Color {
        switch index {
        case 0: return .orange
        case 1: return Color(white: 0.62)
        case 2: return Color(red: 0.72, green: 0.45, blue: 0.20)
        default: return .secondary
        }
    }

    private func reload() async {
        if let list = try? await APIClient.shared.getSponsors() {
            store.sponsors = list
        }
    }

    static func money(_ value: Double) -> String {
        if value == value.rounded() { return String(format: "%.0f", value) }
        return String(format: "%.2f", value)
    }
}
