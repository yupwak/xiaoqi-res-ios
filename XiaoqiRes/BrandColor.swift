import SwiftUI
import UIKit

extension Color {
    /// 与官网一致的「获取」按钮底色：深色模式用站点原色 #0091FE，浅色模式用加深版
    static var getButton: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.000, green: 0.569, blue: 0.996, alpha: 1)
                : UIColor(red: 0.000, green: 0.431, blue: 0.870, alpha: 1)
        })
    }
}
