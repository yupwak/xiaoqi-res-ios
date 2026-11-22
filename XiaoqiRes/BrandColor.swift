import SwiftUI
import UIKit

extension Color {
    /// 详情页「立即获取」：官网原色，浅色模式压暗一档
    static var getButton: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.000, green: 0.569, blue: 0.996, alpha: 1)
                : UIColor(red: 0.000, green: 0.431, blue: 0.870, alpha: 1)
        })
    }

    /// 列表「获取」按钮：底 #1C1C1E / 字 #0A8FFD
    static let getButtonFill = Color(red: 28.0 / 255.0, green: 28.0 / 255.0, blue: 30.0 / 255.0)
    static let getButtonText = Color(red: 10.0 / 255.0, green: 143.0 / 255.0, blue: 253.0 / 255.0)
}
