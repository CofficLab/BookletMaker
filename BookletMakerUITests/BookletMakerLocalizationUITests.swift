#if os(macOS)
import XCTest

final class BookletMakerLocalizationUITests: BookletMakerUITestCase {
    func testInterfaceFollowsEnglishAndChineseSystemLanguages() {
        // 英文环境：内置演示 PDF + 设置区英文文案。
        let demoSample = text("Built-in demo PDF")
        XCTAssertTrue(demoSample.waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertTrue(text("Booklet Settings").waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(text("Output paper").exists)
        XCTAssertFalse(text("小册子设置").exists)

        app.terminate()
        launchApp(language: "zh-Hans", locale: "zh_CN")

        // 中文环境：内置演示 PDF + 设置区中文文案。
        let localizedDemoSample = text("内置演示 PDF")
        XCTAssertTrue(localizedDemoSample.waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertTrue(text("小册子设置").waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(text("输出纸张").exists)
        XCTAssertFalse(text("Booklet Settings").exists)
        XCTAssertTrue(text("书本折叠").exists, "版式下拉应为中文（书本折叠）")

        // 切到「拆分 PDF」工具后出现拆分 UI。
        let splitTool = app.radioButtons.matching(NSPredicate(format: "label IN %@", ["拆分 PDF", "Split PDF"])).firstMatch
        XCTAssertTrue(splitTool.waitForExistence(timeout: 5))
        splitTool.click()
        // 首击可能被窗口激活竞态吞掉（只激活不切换工具），未出现则重试。
        if !text("页面序列").waitForExistence(timeout: 5) {
            splitTool.click()
        }
        XCTAssertTrue(text("页面序列").waitForExistence(timeout: 10), "拆分视图缺少页面序列")
        XCTAssertTrue(text("拆分结果").exists)
    }

    /// 设置侧边栏跟随系统语言切换（en ↔ zh-Hans），且不残留另一语言的标题。
    ///
    /// 侧边栏条目由共享设置组件渲染、不带 accessibility identifier，按标题定位。
    /// BookletMaker 的侧边栏只有「通用 / 外观」两个入口；共享插件包
    /// `LumiPluginPluginManager` 的「插件管理」入口在本宿主被跳过
    /// （本宿主插件策略均为 required / alwaysOn，那个页面必然是空的）。
    func testSettingsSidebarFollowsSystemLanguages() {
        // 英文环境：设置侧边栏为 General / Appearance。
        openSettings()
        XCTAssertTrue(
            settingsButton("General").waitForExistence(timeout: 10),
            "英文设置侧边栏缺少 General。\(app.debugDescription)"
        )
        XCTAssertTrue(settingsButton("Appearance").exists, "英文设置侧边栏缺少 Appearance")
        XCTAssertFalse(settingsButton("通用").exists, "英文设置侧边栏错误显示「通用」")
        XCTAssertFalse(settingsButton("外观").exists, "英文设置侧边栏错误显示「外观」")
        closeSettings()

        app.terminate()
        launchApp(language: "zh-Hans", locale: "zh_CN")

        // 中文环境：设置侧边栏为 通用 / 外观。
        openSettings()
        XCTAssertTrue(
            settingsButton("通用").waitForExistence(timeout: 10),
            "中文设置侧边栏缺少「通用」。\(app.debugDescription)"
        )
        XCTAssertTrue(settingsButton("外观").exists, "中文设置侧边栏缺少「外观」")
        XCTAssertFalse(settingsButton("General").exists, "中文设置侧边栏错误显示 General")
        XCTAssertFalse(settingsButton("Appearance").exists, "中文设置侧边栏错误显示 Appearance")
    }
}
#endif
