#if os(macOS)
import XCTest

/// 设置窗口：默认入口、侧边栏切换详情页、关闭重开后保持选中、外观页控件。
///
/// 侧边栏条目由共享设置组件（LumiUI `AppSettingsSidebarItem`）渲染，不带
/// accessibility identifier，按标题定位（label/identifier 双匹配 + CONTAINS 兜底，
/// 因为 Button 的 AX label 可能拼接了 SF Symbol 图标名）。
/// 基类固定英文环境，侧边栏只有「General / Appearance」两个条目：
/// 共享插件包 `LumiPluginPluginManager` 的「Plugin Manager」入口在本宿主被
/// 跳过 —— 本宿主插件策略均为 required / alwaysOn，那个页面必然是空的。
final class BookletMakerSettingsUITests: BookletMakerUITestCase {

    /// 全新启动打开设置窗口：详情区默认显示第一个入口「通用」的页面。
    ///
    /// 断言依据：「Version」行仅存在于通用页（GeneralSettingsDetailView）；
    /// 外观页标记为筛选段「All」与主题计数「N Themes」（ThemeSettingsDetailView）。
    func testSettingsDefaultsToGeneralPageOnFreshLaunch() {
        openSettings()

        XCTAssertTrue(
            settingsButton("General").exists,
            "侧边栏缺少 General 入口。\(app.debugDescription)"
        )
        XCTAssertTrue(
            settingsButton("Appearance").exists,
            "侧边栏缺少 Appearance 入口。\(app.debugDescription)"
        )
        XCTAssertTrue(
            settingsText("Version").waitForExistence(timeout: 5),
            "详情区应默认显示通用页（Version 行）。\(app.debugDescription)"
        )
        XCTAssertFalse(
            settingsText("All").exists,
            "外观页不应是默认选中项"
        )
        XCTAssertFalse(
            settingsTextContaining("Themes").exists,
            "外观页不应是默认选中项（主题计数出现）"
        )
    }

    /// 侧边栏不应出现「Plugin Manager」入口。
    ///
    /// 本宿主插件策略均为 required / alwaysOn，插件管理页必然是一个永远为空的
    /// 列表 —— 这样的入口对用户没有意义，反而让人以为功能坏了。
    ///
    /// 这条守卫盯住「共享插件包恢复成无条件注册入口」这个坑：远程包
    /// `LumiPluginPluginManager` 的默认策略是「仅当宿主存在可配置插件时注册」，
    /// 一旦改回无条件注册，这里就会红。
    func testSettingsSidebarHasNoPluginManagerEntry() {
        openSettings()

        XCTAssertTrue(
            settingsButton("General").waitForExistence(timeout: 10),
            "侧边栏缺少 General 入口。\(app.debugDescription)"
        )
        XCTAssertFalse(
            settingsButton("Plugin Manager").exists,
            "宿主没有可配置插件，侧边栏不应出现 Plugin Manager 入口。\(app.debugDescription)"
        )
        XCTAssertFalse(
            settingsButton("插件管理").exists,
            "宿主没有可配置插件，侧边栏不应出现「插件管理」入口。\(app.debugDescription)"
        )
    }

    /// 侧边栏在「通用 ↔ 外观」间切换，详情区随之更新。
    func testSidebarEntrySwitchesBetweenGeneralAndAppearance() {
        openSettings()
        XCTAssertTrue(settingsText("Version").waitForExistence(timeout: 5))

        // 切到外观：出现筛选段与主题计数，通用页标记消失。
        clickSetting(settingsButton("Appearance"))
        XCTAssertTrue(
            settingsText("All").waitForExistence(timeout: 5),
            "外观页未显示（缺少 All 筛选段）。\(app.debugDescription)"
        )
        XCTAssertTrue(settingsTextContaining("Themes").exists, "外观页缺少主题计数")
        XCTAssertFalse(settingsText("Version").exists, "详情区仍停留在通用页")

        // 切回通用。
        clickSetting(settingsButton("General"))
        XCTAssertTrue(
            settingsText("Version").waitForExistence(timeout: 5),
            "未切回通用页。\(app.debugDescription)"
        )
        XCTAssertFalse(settingsText("All").exists, "详情区仍停留在外观页")
    }

    /// 本次运行内切到「外观」后关闭再打开设置窗口：选中态保持（不重置回第一个）。
    ///
    /// 关闭前先点击侧边栏，保证设置窗口是 key window（⌘W 关闭 key window）。
    /// 重开用工具栏齿轮而非 ⌘,——后者携带 `entryID=general` 深链会重置选中态。
    func testSettingsKeepsLastSelectedEntryAfterWindowReopen() {
        openSettings()

        let appearance = settingsButton("Appearance")
        XCTAssertTrue(appearance.waitForExistence(timeout: 5), "侧边栏缺少 Appearance 入口")
        clickSetting(appearance)
        XCTAssertTrue(
            settingsText("All").waitForExistence(timeout: 5),
            "外观页未显示。\(app.debugDescription)"
        )

        // 关闭设置窗口（⌘W），确认已关闭。
        closeSettings()

        // 重新打开：应停留在「外观」，而不是重置回「通用」。
        openSettings()
        XCTAssertTrue(
            settingsText("All").waitForExistence(timeout: 5),
            "重开设置窗口后应保持在外观页。\(app.debugDescription)"
        )
        XCTAssertFalse(
            settingsText("Version").exists,
            "重开后选中态被重置回通用页"
        )
    }

    /// 外观页由共享 LumiThemePack 渲染：筛选段（All/Dark）存在、主题计数出现，
    /// 且设置窗口保持打开。
    ///
    /// 外观页已移除主题搜索，搜索输入框不应再存在。
    func testAppearancePageShowsThemeFiltersWithoutSearch() {
        openSettings()

        let appearance = settingsButton("Appearance")
        XCTAssertTrue(appearance.waitForExistence(timeout: 5), "侧边栏缺少 Appearance 入口")
        clickSetting(appearance)

        XCTAssertTrue(
            settingsText("All").waitForExistence(timeout: 5),
            "外观页缺少 All 筛选段。\(app.debugDescription)"
        )
        XCTAssertTrue(settingsText("Dark").exists, "外观页缺少 Dark 筛选段")
        XCTAssertTrue(
            settingsTextContaining("Themes").waitForExistence(timeout: 5),
            "外观页缺少主题计数标题"
        )
        XCTAssertFalse(
            settingsWindow.textFields.firstMatch.exists,
            "外观页不应再显示主题搜索输入框"
        )
        XCTAssertTrue(
            settingsWindow.exists,
            "外观页打开后设置窗口意外关闭"
        )
    }

    /// 通用页有「关于我们」分组：官网 / 隐私政策 / 服务条款三条都在。
    ///
    /// 这三条是 App Store 审核的硬要求（隐私政策必须可达），也是本宿主
    /// 注入 `BookletMakerLegalLinks` 的唯一落点 —— 共享设置插件只在配置里
    /// 拿到链接时才画这个分组，链接没注入就不会有任何一条。
    func testGeneralPageShowsAboutUsGroupWithLegalLinks() {
        openSettings()

        XCTAssertTrue(
            settingsText("Version").waitForExistence(timeout: 5),
            "详情区应默认显示通用页（Version 行）。\(app.debugDescription)"
        )

        // 分组标题
        XCTAssertTrue(
            settingsText("About Us").waitForExistence(timeout: 5),
            "通用页缺少「关于我们」分组标题。\(app.debugDescription)"
        )

        // 三条法律链接
        XCTAssertTrue(
            settingsText("Official Website").exists,
            "「关于我们」缺少官方网站行。\(app.debugDescription)"
        )
        XCTAssertTrue(
            settingsText("Privacy Policy").exists,
            "「关于我们」缺少隐私政策行。\(app.debugDescription)"
        )
        XCTAssertTrue(
            settingsText("Terms of Service").exists,
            "「关于我们」缺少服务条款行。\(app.debugDescription)"
        )
    }

    /// 官网行展示的是链接主机名（coffic.cn），不是原始 URL。
    ///
    /// 断言依据：视图里用 `websiteURL.host ?? absoluteString` 作为行副标题。
    func testGeneralPageShowsWebsiteHostAsDescription() {
        openSettings()

        XCTAssertTrue(
            settingsText("Official Website").waitForExistence(timeout: 5),
            "通用页缺少官方网站行。\(app.debugDescription)"
        )
        XCTAssertTrue(
            settingsTextContaining("coffic.cn").exists,
            "官方网站行未展示主机名。\(app.debugDescription)"
        )
    }
}
#endif
