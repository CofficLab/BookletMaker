#if os(iOS)
import XCTest

final class BookletMakerIOSUITests: BookletMakerUITestCase {
    /// 小册子主线：首页选工具 → 全屏引导 → 六步向导 → 导出。
    ///
    /// 回归重点：这条链路曾经被换成「顶部一排标签页 + 两列缩略图网格」，
    /// 与产品原型（3/6 拼版预览 → 4/6 纸张与版式 → 5/6 总览 → 6/6 导出）
    /// 完全不符。这里逐阶段断言阶段标题与步进按钮，把原型结构钉住。
    func testBookletSampleCanBeReviewedAndExported() {
        let bookletTool = app.buttons["welcome.bookletTool"]
        XCTAssertTrue(bookletTool.waitForExistence(timeout: 10))
        bookletTool.tap()

        // 引导共两屏：第一屏讲原理，第二屏收文件。第一屏只有「下一步」。
        let nextGuideStep = app.buttons["guide.next"]
        XCTAssertTrue(nextGuideStep.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["guide.useSample"].exists,
                       "样例入口只在引导最后一屏出现")
        nextGuideStep.tap()

        let useSample = app.buttons["guide.useSample"]
        XCTAssertTrue(useSample.waitForExistence(timeout: 5))
        useSample.tap()

        // 引导关闭后应当已经站在小册子工作台，而不是概览页。
        let stageTitle = app.staticTexts["booklet.stageTitle"]
        XCTAssertTrue(stageTitle.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertEqual(stageTitle.label, "Print Layout")

        // 每张物理纸都能切到背面 —— 双面打印的背面此前被静默砍掉。
        let backSide = app.buttons["booklet.side.0.back"]
        XCTAssertTrue(backSide.waitForExistence(timeout: 5),
                      "拼版预览应提供每张纸的「背面」切换。\(app.debugDescription)")

        // 六步向导：底部「下一步」线性推进，而不是靠标签页跳转。
        let nextStage = app.buttons["booklet.stepNext"]
        XCTAssertTrue(nextStage.exists, "缺少底部「下一步」按钮。\(app.debugDescription)")
        nextStage.tap()
        XCTAssertEqual(stageTitle.waitForValue("Paper and Layout", timeout: 5), "Paper and Layout")

        nextStage.tap()
        XCTAssertEqual(stageTitle.waitForValue("Review", timeout: 5), "Review")
        XCTAssertTrue(app.staticTexts["Preview the booklet"].exists,
                      "总览页应保留翻页跨页预览。\(app.debugDescription)")

        nextStage.tap()
        XCTAssertEqual(stageTitle.waitForValue("Export", timeout: 5), "Export")
        XCTAssertTrue(app.staticTexts["Your booklet PDF is ready"].waitForExistence(timeout: 30),
                      app.debugDescription)
    }

    /// 拆分主线：首页选工具 → 单屏引导 → 标记切点 → 导出。
    func testSplitSampleOpensSplitPlan() {
        let splitTool = app.buttons["welcome.splitTool"]
        XCTAssertTrue(splitTool.waitForExistence(timeout: 10))
        splitTool.tap()

        // 拆分只有一屏引导，不需要「下一步」。
        XCTAssertFalse(app.buttons["guide.next"].waitForExistence(timeout: 2),
                       "拆分引导应在一屏内讲完")

        let useSample = app.buttons["guide.useSample"]
        XCTAssertTrue(useSample.waitForExistence(timeout: 5))
        useSample.tap()

        XCTAssertTrue(app.staticTexts["Split Plan"].waitForExistence(timeout: 10))
        let splitButton = app.buttons["split.export"]
        XCTAssertTrue(splitButton.waitForExistence(timeout: 10))
        XCTAssertFalse(splitButton.isEnabled, "Splitting is unavailable until a boundary is selected")

        // 滑动浏览页面，点页面之间的剪刀标记切分点。
        let splitBoundary = app.buttons["split.boundary.1"]
        XCTAssertTrue(splitBoundary.waitForExistence(timeout: 5), app.debugDescription)
        splitBoundary.tap()

        XCTAssertTrue(splitButton.isEnabled)
        splitButton.tap()
        XCTAssertTrue(app.staticTexts["Your PDF is ready"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts["2 files created on this device"].waitForExistence(timeout: 5))
    }

    /// 合并主线：合并至少要两个文件，因此引导里没有「使用示例」入口。
    func testMergeGuideOffersNoSampleDocument() {
        let mergeTool = app.buttons["welcome.mergeTool"]
        XCTAssertTrue(mergeTool.waitForExistence(timeout: 10))
        mergeTool.tap()

        let nextGuideStep = app.buttons["guide.next"]
        XCTAssertTrue(nextGuideStep.waitForExistence(timeout: 5))
        nextGuideStep.tap()

        XCTAssertTrue(app.buttons["guide.openPDF"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["guide.useSample"].exists,
                       "单个示例文件演示不了合并，不应提供该入口")
    }

    /// 设置 - 通用：导航栏齿轮 →「General」→ 详情页出现 Version 行。
    ///
    /// 截图存档供视觉回归检查：详情页背景应与主题/系统外观一致。
    /// 历史 bug：iOS 侧未桥接 LumiUI 主题时，`AppSettingsContentScaffold`
    /// 用 `UnconfiguredChromeTheme`（固定暗色）的 panel 铺满整页，在亮色
    /// 系统下呈现「白顶栏 + 浅卡片 + 整页黑底」的混搭。
    ///
    /// 入口行用 accessibility identifier 定位（`kuzee.settings.entry.general`）：
    /// iOS 根页是分组列表，「General」既可能出现在分组标题也可能出现在行上，
    /// 按文字定位会命中分组标题（点它没有任何反应）。
    func testSettingsGeneralPageOpensAndAttachesScreenshot() {
        let gear = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["设置", "Settings", "gearshape", "齿轮形状", "Gear Shape"])
        ).firstMatch
        XCTAssertTrue(gear.waitForExistence(timeout: 10), app.debugDescription)
        gear.tap()

        let general = app.buttons["kuzee.settings.entry.general"]
        XCTAssertTrue(general.waitForExistence(timeout: 10), app.debugDescription)
        general.tap()

        XCTAssertTrue(
            app.staticTexts["Version"].waitForExistence(timeout: 10),
            "设置-通用详情页未出现 Version 行。\(app.debugDescription)"
        )

        // 等 sheet 与导航转场动画结束后再截图。
        Thread.sleep(forTimeInterval: 1.5)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "settings-general"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 设置根页：齿轮能打开设置，且根页是「入口 + 搜索」的 iOS 列表。
    ///
    /// 回归重点：设置齿轮必须挂在 App **自己的**系统导航栏上 ——
    /// SwiftUI 不会把外层的 `.toolbar` 传递进嵌套的 `NavigationStack`，
    /// 齿轮一旦挂错层级，设置入口就整体不可达（曾经真实发生过）。
    func testSettingsRootListShowsEntriesAndSearch() {
        let gear = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["设置", "Settings", "gearshape", "齿轮形状", "Gear Shape"])
        ).firstMatch
        XCTAssertTrue(gear.waitForExistence(timeout: 10), "导航栏缺少设置齿轮。\(app.debugDescription)")
        gear.tap()

        XCTAssertTrue(
            app.buttons["kuzee.settings.entry.general"].waitForExistence(timeout: 10),
            "设置根页缺少 General 入口。\(app.debugDescription)"
        )
        XCTAssertTrue(
            app.buttons["kuzee.settings.entry.appearance"].waitForExistence(timeout: 5),
            "设置根页缺少 Appearance 入口。\(app.debugDescription)"
        )
        XCTAssertTrue(
            app.searchFields.firstMatch.waitForExistence(timeout: 5),
            "设置根页缺少搜索框。\(app.debugDescription)"
        )

        Thread.sleep(forTimeInterval: 1.0)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "settings-root"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 设置 - 外观：主题列表 + 当前主题对勾。
    ///
    /// 回归重点：iOS 侧外观页是「点主题即应用 + 行尾对勾」，没有额外的
    /// 「使用」按钮；当前选中项必须带对勾标记。
    func testSettingsAppearancePageListsThemesWithCheckmark() {
        let gear = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["设置", "Settings", "gearshape", "齿轮形状", "Gear Shape"])
        ).firstMatch
        XCTAssertTrue(gear.waitForExistence(timeout: 10), app.debugDescription)
        gear.tap()

        let appearance = app.buttons["kuzee.settings.entry.appearance"]
        XCTAssertTrue(appearance.waitForExistence(timeout: 10), app.debugDescription)
        appearance.tap()

        // 主题计数标题（"22 Themes" 之类，数量随主题包变化，用包含匹配）。
        let themeCount = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Themes")
        ).firstMatch
        XCTAssertTrue(themeCount.waitForExistence(timeout: 10), "外观页缺少主题列表。\(app.debugDescription)")

        // 当前主题行尾的对勾。
        XCTAssertTrue(
            app.images.matching(identifier: "checkmark").firstMatch.waitForExistence(timeout: 5),
            "当前主题缺少对勾标记。\(app.debugDescription)"
        )

        Thread.sleep(forTimeInterval: 1.0)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "settings-appearance"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 设置 - 通用：出现「关于我们」分组，含官网 / 隐私政策 / 服务条款。
    ///
    /// 回归重点：iOS 与 macOS 是同一款 App（universal purchase），隐私政策
    /// 链接在两端都必须可达 —— App Store 审核的硬要求。iOS 侧「关于我们」
    /// 是独立分组（不混在「支持」里），三条法律链接都要能点到。
    func testSettingsGeneralPageShowsAboutUsGroup() {
        let gear = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["设置", "Settings", "gearshape", "齿轮形状", "Gear Shape"])
        ).firstMatch
        XCTAssertTrue(gear.waitForExistence(timeout: 10), app.debugDescription)
        gear.tap()

        let general = app.buttons["kuzee.settings.entry.general"]
        XCTAssertTrue(general.waitForExistence(timeout: 10), app.debugDescription)
        general.tap()

        XCTAssertTrue(
            app.staticTexts["Version"].waitForExistence(timeout: 10),
            "设置-通用详情页未出现 Version 行。\(app.debugDescription)"
        )

        // 分组标题（英文 About Us / 中文 关于我们）。
        let aboutTitle = app.staticTexts.matching(
            NSPredicate(format: "label == %@ OR label == %@", "About Us", "关于我们")
        ).firstMatch
        XCTAssertTrue(
            aboutTitle.waitForExistence(timeout: 10),
            "设置-通用缺少「关于我们」分组。\(app.debugDescription)"
        )

        // 三条法律链接。
        for title in ["Official Website", "Privacy Policy", "Terms of Service"] {
            XCTAssertTrue(
                app.staticTexts[title].exists,
                "「关于我们」缺少 \(title) 行。\(app.debugDescription)"
            )
        }
    }

    /// 工具栏右上角是「首页」按钮，不再是「更多」菜单。
    ///
    /// 回归重点：工具工作台是导航栈的栈顶根页，没有返回按钮——首页按钮
    /// 是离开工作台的唯一路径。它只在工作台阶段出现，首页自己不需要。
    func testHomeButtonReplacesTheDocumentMenu() {
        // 首页：没有首页按钮，也没有「更多」菜单。
        XCTAssertFalse(
            app.buttons["home.button"].exists,
            "首页不应出现首页按钮。\(app.debugDescription)"
        )
        XCTAssertFalse(
            app.buttons.matching(
                NSPredicate(format: "label IN %@", ["文档菜单", "Document menu", "更多", "More"])
            ).firstMatch.exists,
            "首页不应残留「更多」菜单。\(app.debugDescription)"
        )

        // 进入工作台：首页按钮出现，「更多」菜单消失。
        let bookletTool = app.buttons["welcome.bookletTool"]
        XCTAssertTrue(bookletTool.waitForExistence(timeout: 10))
        bookletTool.tap()

        // 小册子引导共两屏：第一屏讲原理，第二屏收文件。
        let nextGuideStep = app.buttons["guide.next"]
        XCTAssertTrue(nextGuideStep.waitForExistence(timeout: 10), app.debugDescription)
        nextGuideStep.tap()

        let useSample = app.buttons["guide.useSample"]
        XCTAssertTrue(useSample.waitForExistence(timeout: 10), app.debugDescription)
        useSample.tap()

        XCTAssertTrue(
            app.buttons["home.button"].waitForExistence(timeout: 10),
            "工作台缺少首页按钮。\(app.debugDescription)"
        )
        XCTAssertFalse(
            app.buttons.matching(
                NSPredicate(format: "label IN %@", ["文档菜单", "Document menu", "更多", "More"])
            ).firstMatch.exists,
            "工作台不应残留「更多」菜单。\(app.debugDescription)"
        )

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "home-button"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 首页按钮能带着用户回到首页。
    func testHomeButtonReturnsToTheLandingPage() {
        let bookletTool = app.buttons["welcome.bookletTool"]
        XCTAssertTrue(bookletTool.waitForExistence(timeout: 10))
        bookletTool.tap()

        // 小册子引导共两屏。
        let nextGuideStep = app.buttons["guide.next"]
        XCTAssertTrue(nextGuideStep.waitForExistence(timeout: 10), app.debugDescription)
        nextGuideStep.tap()

        let useSample = app.buttons["guide.useSample"]
        XCTAssertTrue(useSample.waitForExistence(timeout: 10), app.debugDescription)
        useSample.tap()

        let home = app.buttons["home.button"]
        XCTAssertTrue(home.waitForExistence(timeout: 10), app.debugDescription)
        home.tap()

        XCTAssertTrue(
            app.buttons["welcome.bookletTool"].waitForExistence(timeout: 10),
            "点首页按钮后未回到首页。\(app.debugDescription)"
        )
    }

    /// 帮助页可达。
    ///
    /// 回归重点：帮助页曾在 1.3.2 被整页删除（连同菜单项），而产品原型
    /// 明确要求能到达「帮助与关于」。
    ///
    /// 工具栏的「更多」菜单移除后，帮助页从导出结果页的「后续操作」进入。
    func testHelpPageIsReachableFromTheExportResult() {
        exportBookletAndWaitForResult()

        let viewGuide = app.buttons["exportResult.viewGuide"]
        XCTAssertTrue(viewGuide.waitForExistence(timeout: 30),
                      "导出结果页缺少「查看指南」入口。\(app.debugDescription)")
        viewGuide.tap()

        // 帮助页标题（英文 Help / 中文 帮助）。
        let helpTitle = app.staticTexts.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Help", "帮助")
        ).firstMatch
        XCTAssertTrue(helpTitle.waitForExistence(timeout: 10),
                      "帮助页未打开。\(app.debugDescription)")

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "help-page"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Helpers

    /// 走完小册子主线，停在导出结果页。
    ///
    /// 导出结果页的「后续操作」区块是产品原型的一部分（原型 `07-export-booklet`
    /// 的「后续操作」：调整参数后重新导出 / 改为拆分这个 PDF / 重新观看引导），
    /// 它曾在共享包迁移时被整块删掉。
    private func exportBookletAndWaitForResult() {
        let bookletTool = app.buttons["welcome.bookletTool"]
        XCTAssertTrue(bookletTool.waitForExistence(timeout: 10))
        bookletTool.tap()

        let nextGuideStep = app.buttons["guide.next"]
        XCTAssertTrue(nextGuideStep.waitForExistence(timeout: 5))
        nextGuideStep.tap()

        let useSample = app.buttons["guide.useSample"]
        XCTAssertTrue(useSample.waitForExistence(timeout: 5))
        useSample.tap()

        // 拼版预览 → 纸张与版式 → 总览 → 导出。
        let nextStage = app.buttons["booklet.stepNext"]
        XCTAssertTrue(nextStage.waitForExistence(timeout: 10), app.debugDescription)
        nextStage.tap()
        nextStage.tap()
        nextStage.tap()
    }

    /// 导出结果页提供「后续操作」区块。
    ///
    /// 回归重点：这一区块曾被整块删除，用户导出后只能回到首页重新开始，
    /// 无法在同一个结果页上调参重导或换工具。
    func testExportResultOffersNextSteps() {
        exportBookletAndWaitForResult()

        let adjust = app.buttons["exportResult.adjustSettings"]
        XCTAssertTrue(adjust.waitForExistence(timeout: 30),
                      "导出结果页缺少「调整参数后重新导出」。\(app.debugDescription)")

        let switchTool = app.buttons["exportResult.switchTool"]
        XCTAssertTrue(switchTool.exists, "导出结果页缺少「改为拆分这个 PDF」。\(app.debugDescription)")

        let viewGuide = app.buttons["exportResult.viewGuide"]
        XCTAssertTrue(viewGuide.exists, "导出结果页缺少「重新观看引导」。\(app.debugDescription)")

        let share = app.buttons["exportResult.share"]
        XCTAssertTrue(share.exists, "导出结果页缺少「分享」。\(app.debugDescription)")

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "export-result-next-steps"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
#endif
