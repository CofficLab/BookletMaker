import LumiFactory
import SwiftUI

#if os(macOS)
/// macOS 场景壳：主窗口组 + 设置窗口 + ⌘, 命令全部由 LumiFactory 提供。
/// delegate adaptor 与启动器注入在 @main 根 App（BookletMakerApp）上完成。
struct BookletMakerMacApp: App {
    var body: some Scene {
        HostMacWindowGroupScenes(bootstrapper: BookletMakerAssembly.bootstrapper).body
    }
}
#endif

/// 主窗口与设置窗口共享的唯一内核引导器。
@MainActor
enum BookletMakerAssembly {
    static let bootstrapper = KernelBootstrapper(manifest: BookletMakerManifest.manifest)
}