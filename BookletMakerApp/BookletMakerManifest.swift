import KernelCore
import LumiFactory
import PluginAbout
import PluginBookletMaker
import PluginPluginManager
import PluginSettingGeneral
import PluginSettingView
import PluginThemePack
import ProviderContentView
import ProviderRootView
import ProviderSettingView
import ProviderStorage
import ProviderTheme
import ProviderUninstall
import SwiftUI

#if os(macOS)
import LumiUI
import PluginActivityBar
import PluginCommand
import ProviderActivityBar
import ProviderRailView
import ProviderToolbar
import WorkbenchRootView
#endif

#if os(iOS)
import ProviderMobileTabBar
import ProviderToolbar
#endif

#if os(visionOS)
import ProviderRailView
#endif

/// BookletMaker 的宿主清单：App 与共享装配引擎 LumiFactory 之间的全部差异。
///
/// 三端形态不同：macOS 是工作台（ActivityBar + Rail + 内容区），iOS 是
/// 移动导航壳 + 设置 sheet，visionOS 是自有窗口壳（标题栏齿轮 + 侧栏 + 内容区）。
/// 插件 id、存储目录与窗口 id 沿用迁移前取值，延续既有用户数据。
@MainActor
enum BookletMakerManifest {
    nonisolated static let settingsWindowID = "booklet-maker.settings"

    /// 本宿主的业务插件标识（覆盖共享包默认的 Lumi 命名空间，数据目录不换位置）。
    nonisolated static let bookletMakerPluginID = "com.coffic.bookletmaker.plugin.booklet-maker"

    /// 共享目录主题白名单（与 ThemePackPlugin 注册同一组）。
    nonisolated static let catalogThemeIDs = [
        "lumi", "sky", "winter", "river", "midnight", "vscode-light",
    ]

    static var manifest: HostManifest {
        let identity = HostIdentity(
            appName: "BookletMaker",
            loggerSubsystem: "com.coffic.bookletmaker.app",
            mainWindowID: "booklet-maker.main",
            settingsWindowID: settingsWindowID,
            accessibilityPrefix: "booklet-maker",
            mainWindowDefaultSize: CGSize(width: 1100, height: 760),
            settingsWindowDefaultSize: CGSize(width: 1000, height: 600)
        )
        var manifest = HostManifest(
            identity: identity,
            makePlugins: { makePlugins() },
            storage: HostStorageConfiguration(stateStorePluginID: "PluginManager"),
            theme: HostThemeConfiguration(
                catalogThemeIDs: catalogThemeIDs,
                storageDirectoryName: "ThemeManager",
                // 迁移前 macOS / visionOS 主题选择存在默认数据根下的 ThemeManager
                // 目录（storage.pluginDataDirectory(for: "ThemeManager")），重定向延续
                // 既有选择；iOS 历来用 AppSupport/<bundleID>/ThemeManager，与基线默认一致。
                migrateLegacySelection: { theme in
                    #if os(macOS) || os(visionOS)
                    (theme as? DefaultThemeProviding)?.setStorageDirectory(
                        DefaultStorageProvider.makeDefaultDataRootDirectory()
                            .appendingPathComponent("ThemeManager", isDirectory: true)
                    )
                    #endif
                }
            ),
            features: makeFeatures()
        )
        #if os(macOS)
        // 工作台根视图自带区域联动（rail 显隐 / 宽度回写 / ActivityBar provider），
        // 共享接线注入的默认内容会被去重守卫锁死，必须关闭并由宿主自行接线。
        manifest.makeRootViewProvider = {
            WorkbenchRootViewProviding(loggerSubsystem: identity.loggerSubsystem)
        }
        manifest.wireKernel = { kernel in
            wireWorkbench(kernel: kernel, identity: identity)
        }
        // 工作台的 Rail 不在 LumiFactory 基线里：宿主必须自行注册，否则
        // 插件贡献的侧栏（导入拖放区、参数、导出按钮）无处渲染。
        manifest.registerProviders = { kernel in
            try kernel.registerProvider((any RailViewProviding).self, DefaultRailViewProviding())
        }
        #elseif os(iOS)
        // iOS 没有工作台，插件改往移动端标签注册表插入整页 UI。
        // 宿主只提供注册表与设置 sheet，不再硬编码 iOS 功能清单：
        // 没有贡献移动入口的插件在 iOS 上自然不出现。
        manifest.registerProviders = { kernel in
            try kernel.registerProvider(
                (any MobileTabBarProviding).self,
                DefaultMobileTabBarProviding()
            )
        }
        manifest.makeMainView = { kernel in
            makeMobileMainView(kernel: kernel, identity: identity)
        }
        #else
        // visionOS 基线不含 ContentView / RailView（非 macOS 默认只有导航栏），
        // 自有窗口壳需要这两块：插件的工具选择 / 导入 / 导出都挂在 rail 上。
        manifest.registerProviders = { kernel in
            try kernel.registerProvider((any ContentViewProviding).self, DefaultContentViewProviding())
            try kernel.registerProvider((any RailViewProviding).self, DefaultRailViewProviding())
        }
        #endif
        return manifest
    }

    private static func makeFeatures() -> HostFeatures {
        #if os(macOS)
        HostFeatures(quitsWhenLastWindowClosed: true, skipsSharedRootViewWiring: true)
        #elseif os(iOS)
        HostFeatures(quitsWhenLastWindowClosed: true)
        #else
        // visionOS 的设置入口是自有窗口壳标题栏上的齿轮，不走导航栏贡献点。
        HostFeatures(showsSettingsToolbarButton: false, quitsWhenLastWindowClosed: true)
        #endif
    }

    // MARK: - Plugins

    static func makePlugins() -> [any SuperPlugin] {
        #if os(macOS)
        return [
            CommandPlugin(),
            PluginSettingView(id: "com.coffic.lumi.plugin.setting-view"),
            SettingGeneralPlugin(configuration: generalConfiguration),
            PluginActivityBar(),
            ThemePackPlugin(themeIDs: catalogThemeIDs),
            PluginPluginManager(),
            AboutPlugin(
                id: "com.coffic.bookletmaker.plugin.about",
                configuration: AboutConfiguration(
                    officialWebsiteURLString: legalWebsite,
                    privacyPolicyURLString: legalPrivacyPolicy,
                    termsOfServiceURLString: legalTermsOfService
                )
            ),
            // BookletMaker 是此宿主的核心能力，不能被用户关闭。
            BookletMakerPlugin(id: bookletMakerPluginID, policy: .required),
        ]
        #elseif os(iOS)
        // BookletMakerPlugin 与 macOS 装配同一份业务插件：桌面贡献工作台，
        // iOS 贡献移动标签注册表里的整页入口。
        return [
            PluginSettingView(id: "com.coffic.lumi.plugin.setting-view"),
            SettingGeneralPlugin(configuration: generalConfiguration),
            ThemePackPlugin(themeIDs: catalogThemeIDs),
            PluginPluginManager(),
            AboutPlugin(
                id: "com.coffic.bookletmaker.plugin.about",
                configuration: AboutConfiguration(
                    officialWebsiteURLString: legalWebsite,
                    privacyPolicyURLString: legalPrivacyPolicy,
                    termsOfServiceURLString: legalTermsOfService
                )
            ),
            BookletMakerPlugin(id: bookletMakerPluginID, policy: .required),
        ]
        #else
        // visionOS 没有菜单栏 / 工具栏宿主，不装配 ActivityBar / Command / About；
        // 设置入口由自有窗口壳提供。
        return [
            SettingGeneralPlugin(configuration: generalConfiguration),
            ThemePackPlugin(themeIDs: catalogThemeIDs),
            PluginPluginManager(),
            BookletMakerPlugin(id: bookletMakerPluginID, policy: .required),
        ]
        #endif
    }

    // MARK: - Branding

    nonisolated static let legalWebsite = "https://coffic.cn/booklet"
    nonisolated static let legalPrivacyPolicy = "https://coffic.cn/privacy"
    nonisolated static let legalTermsOfService = "https://coffic.cn/terms"

    /// 通用设置插件配置：保留迁移前的插件 id（数据目录不换位置）；
    /// 迁移前页面没有更新通道 / CLI / 诊断 / 卸载区块，全部关闭保持一致。
    /// ⌘, 由 HostCommands 提供，插件不再重复注册。
    static let generalConfiguration = SettingGeneralConfiguration(
        pluginID: "com.coffic.shared.plugin.setting-general",
        loggerSubsystem: "com.coffic.shared.plugin.setting-general",
        applicationName: "BookletMaker",
        description: "Registers the General settings entry with app info and manuals.",
        openSettingsNotificationName: "lumi.openSettings",
        uninstallBranding: uninstallBranding,
        showsUpdateChannelSection: false,
        showsCLIInstallSection: false,
        alwaysShowManualsSection: false,
        showsDiagnosticsSection: false,
        showsUninstallSection: false,
        privacyDescription: BookletMakerSharedText.string(
            "Your documents stay on this device. Nothing is uploaded."
        ),
        websiteURLString: legalWebsite,
        privacyPolicyURLString: legalPrivacyPolicy,
        termsOfServiceURLString: legalTermsOfService,
        registersOpenSettingsCommand: false
    )

    static let uninstallBranding = UninstallBranding(
        applicationName: "BookletMaker",
        willUninstallNotificationName: UninstallBranding.notificationName(forBrandIdentifier: "bookletmaker"),
        confirmationPhrase: "删除 BookletMaker 数据",
        applicationDataDisplayName: "BookletMaker 数据",
        applicationDisplayName: "BookletMaker 应用",
        whitelistDescriptionName: "BookletMaker",
        bundleIdentifierPrefix: "com.coffic.bookletmaker",
        legacyBundleIdentifier: "com.coffic.bookletmaker",
        appGroupIdentifiers: [],
        debugAppGroupIdentifiers: [],
        legacyApplicationSupportDirectories: ["com.coffic.bookletmaker"],
        keychainServices: [],
        debugKeychainServices: []
    )

    // MARK: - macOS Workbench Wiring

    #if os(macOS)
    /// 工作台接线：工具栏（含设置齿轮）/ ActivityBar / Rail / 内容区。
    ///
    /// 共享接线面向通用区域模型，工作台根视图的区域联动（rail 显隐跟随
    /// hasVisibleTabs、宽度回写、ActivityBar provider 注入）由这里完成。
    private static func wireWorkbench(kernel: KernelCoreContainer, identity: HostIdentity) {
        guard let rootView = kernel.resolveProvider((any RootViewProviding).self)
            as? WorkbenchRootViewProviding else { return }

        if let toolbar = kernel.resolveProvider((any ToolbarProviding).self) {
            toolbar.addToolbarItems([settingsToolbarItem(prefix: identity.accessibilityPrefix)])
            rootView.setToolbarView(toolbar.makeToolbarView())
        }
        if let activityBar = kernel.resolveProvider((any ActivityBarProviding).self) {
            rootView.setActivityBarProvider(activityBar)
        }
        if let rail = kernel.resolveProvider((any RailViewProviding).self) {
            rootView.setRailView(rail.makeRailView())
            rootView.bindRailViewVisibility(to: rail)
            rootView.bindRailViewWidth(
                to: rail,
                onResize: { width in rail.saveCurrentWidth(width) }
            )
        }
        if let content = kernel.resolveProvider((any ContentViewProviding).self) {
            rootView.setContentView(
                AnyView(
                    content.makeContentView()
                        .accessibilityIdentifier("\(identity.accessibilityPrefix).main.window")
                )
            )
        }
    }

    /// 主窗口工具栏右侧的设置齿轮（与 LumiFactory 内置齿轮同一语义：
    /// 发「打开设置」通知，由 HostAppDelegate 监听并打开设置窗口）。
    private static func settingsToolbarItem(prefix: String) -> ProviderToolbar.ToolbarItem {
        ProviderToolbar.ToolbarItem(
            id: "settings",
            title: BookletMakerSharedText.string("Settings"),
            placement: .trailing,
            category: .global,
            order: 300
        ) {
            AppIconButton(systemImage: "gearshape") {
                NotificationCenter.default.post(
                    name: SettingViewNavigation.openSettingsNotification,
                    object: nil
                )
            }
            .accessibilityIdentifier("\(prefix).toolbar.settings")
        }
    }
    #endif

    // MARK: - iOS Shell

    #if os(iOS)
    private static func makeMobileMainView(
        kernel: KernelCoreContainer,
        identity: HostIdentity
    ) -> AnyView {
        guard let tabs = kernel.resolveProvider((any MobileTabBarProviding).self) else {
            return AnyView(
                ContentUnavailableView(
                    BookletMakerSharedText.string("Booklet Maker unavailable"),
                    systemImage: "doc.on.doc"
                )
                .accessibilityIdentifier("booklet-maker.main.window")
            )
        }
        let shell = AnyView(BookletMakerMobileShell(tabs: tabs))
        guard let navigationBar = kernel.resolveProvider((any IOSNavigationBarProviding).self) else {
            return shell
        }
        // 设置仍是导航栏齿轮 + sheet：齿轮由工厂贡献到导航栏注册表，
        // 插件页面自己把注册表项挂到页内导航栈上。
        return AnyView(
            IOSSettingsAppShell(
                title: identity.appName,
                mainView: shell,
                settingsView: makeMobileSettingsView(kernel: kernel),
                navigationBarProvider: navigationBar,
                navigationBarMode: .host
            )
        )
    }

    private static func makeMobileSettingsView(kernel: KernelCoreContainer) -> AnyView {
        guard let settings = kernel.resolveProvider((any SettingViewProviding).self) else {
            return AnyView(Text(BookletMakerSharedText.string("Settings unavailable")))
        }
        let view = AnyView(settings.makeSettingView())
        guard let theme = kernel.resolveProvider((any ThemeProviding).self) else {
            return view
        }
        return AnyView(HostThemeView(theme: theme, content: view))
    }
    #endif
}