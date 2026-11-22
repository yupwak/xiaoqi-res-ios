import SwiftUI

enum Theme {
    static let background = Color(red: 0.024, green: 0.024, blue: 0.031)
    static let accent = Color(red: 0.13, green: 0.83, blue: 0.93)
    static let accent2 = Color(red: 0.66, green: 0.33, blue: 0.97)
    static let stroke = Color.white.opacity(0.09)

    static var brand: LinearGradient {
        LinearGradient(colors: [accent, accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            Theme.background
            RadialGradient(colors: [Theme.accent2.opacity(0.18), .clear],
                           center: .topLeading, startRadius: 0, endRadius: 460)
            RadialGradient(colors: [Theme.accent.opacity(0.12), .clear],
                           center: .bottomTrailing, startRadius: 0, endRadius: 400)
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// iOS 26 Liquid Glass，低版本回落到材质
    @ViewBuilder
    func glassCard(_ radius: CGFloat = 22) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Theme.stroke, lineWidth: 0.8)
                )
        }
    }

    @ViewBuilder
    func glassPill() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: Capsule())
        } else {
            self
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 0.8))
        }
    }

    @ViewBuilder
    func glassInteractiveCapsule() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            self
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 0.8))
        }
    }
}
