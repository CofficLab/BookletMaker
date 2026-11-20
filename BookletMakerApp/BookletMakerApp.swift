import LumiFactory
import SwiftUI

/// 应用入口：按平台选择对应的实现。
/// - macOS: BookletMakerMacApp
/// - iOS / iPadOS: BookletMakerIOSApp
/// - visionOS: BookletMakerVisionApp
///
/// delegate adaptor 必须挂在 @main 根 App 上：SwiftUI 只为根 App 安装
/// NSApplicationDelegateAdaptor，嵌套 App 结构体上的 adaptor 不会生效。
@main
struct BookletMakerApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: HostAppDelegate
    #endif

    init() {
        #if os(macOS)
        // 禁用窗口状态恢复必须在根 App.init 写入（恢复发生在 delegate 回调之前）。
        HostAppDelegate.prepareForLaunch()
        appDelegate.bootstrapper = BookletMakerAssembly.bootstrapper
        #endif
    }

    var body: some Scene {
        #if os(macOS)
        BookletMakerMacApp().body
        #elseif os(visionOS)
        BookletMakerVisionApp().body
        #else
        BookletMakerIOSApp().body
        #endif
    }
}
