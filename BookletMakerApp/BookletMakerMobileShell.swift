#if !os(macOS)
import Combine
import KernelCore
import ProviderMobileTabBar
import SwiftUI

/// iOS 主界面：只消费插件注册的移动端入口，宿主不再声明功能清单。
///
/// 插件在 `onBoot` / `onEnable` 里往 `MobileTabBarProviding` 注册整页 UI，
/// 禁用或卸载时内核自动撤回；壳观察注册表重建界面。只贡献一个入口时直接
/// 全屏渲染（Booklet Maker 页面自带导航栈与全屏流程），多个入口时才落到
/// `TabView`，没有入口则给出空状态而不是伪造功能。
@MainActor
struct BookletMakerMobileShell: View {
    @StateObject private var observer: MobileTabBarObserver

    init(tabs: any MobileTabBarProviding) {
        _observer = StateObject(wrappedValue: MobileTabBarObserver(provider: tabs))
    }

    var body: some View {
        Group {
            if observer.items.isEmpty {
                ContentUnavailableView(
                    BookletMakerSharedText.string("Booklet Maker unavailable"),
                    systemImage: "doc.on.doc"
                )
            } else if observer.items.count == 1 {
                observer.items[0].makeContent()
            } else {
                TabView {
                    ForEach(observer.items) { item in
                        item.makeContent()
                            .tabItem {
                                Label(item.title, systemImage: item.systemImage)
                            }
                            .tag(item.id)
                    }
                }
            }
        }
        .accessibilityIdentifier("booklet-maker.main.window")
    }
}

/// Provider 注册表按协议类型存放，这里把协议存在类型转成可观察视图模型。
@MainActor
private final class MobileTabBarObserver: ObservableObject {
    private let provider: any MobileTabBarProviding
    private var cancellable: AnyCancellable?

    var items: [MobileTabBarItem] { provider.items }

    init(provider: any MobileTabBarProviding) {
        self.provider = provider
        cancellable = provider.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}
#endif