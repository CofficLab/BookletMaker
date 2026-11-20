#if os(iOS)
import LumiFactory
import SwiftUI

/// iOS 应用入口：装配与场景根视图由 LumiFactory 提供。
struct BookletMakerIOSApp: App {
    var body: some Scene {
        WindowGroup("BookletMaker", id: "booklet-maker.main") {
            HostRootWindowView(bootstrapper: BookletMakerAssembly.bootstrapper)
        }
    }
}
#endif