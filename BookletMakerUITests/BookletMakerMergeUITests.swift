#if os(macOS)
import XCTest

/// UI coverage for the "Merge PDF" tool on macOS.
///
/// Scope note: adding source files on macOS goes through `NSOpenPanel.runModal()`,
/// which XCTest cannot drive reliably (the panel runs outside the app's AX tree
/// and its file listing depends on the user's recent folders). These tests
/// therefore cover every merge state that is reachable without the panel:
/// tool switching, the empty queue, the rail summary, the export button's
/// enabled/disabled gating, and localisation. The queue mechanics themselves
/// (ordering, page counts, export) are covered by unit tests in
/// LumiPluginBookletMaker.
final class BookletMakerMergeUITests: BookletMakerUITestCase {

    /// Switch to the Merge tool and wait for the merge workspace to appear.
    ///
    /// The first click can be swallowed by the macOS window-activation race
    /// (it activates the window without delivering the click), so a missing
    /// merge view triggers one retry.
    private func switchToMergeTool() -> XCUIElement {
        let mergeTool = element("overview.mergeTool")
        XCTAssertTrue(
            mergeTool.waitForExistence(timeout: 15),
            "合并工具入口缺失。\(app.debugDescription)"
        )
        mergeTool.click()

        let emptyState = element("merge.emptyState")
        if !emptyState.waitForExistence(timeout: 5) {
            mergeTool.click()
        }
        XCTAssertTrue(
            emptyState.waitForExistence(timeout: 10),
            "切换到合并工具后未出现空态视图。\(app.debugDescription)"
        )
        return mergeTool
    }

    func testMergeToolStartsWithAnEmptyQueueAndBlockedExport() {
        XCTAssertTrue(
            text("Built-in demo PDF").waitForExistence(timeout: 15),
            app.debugDescription
        )

        switchToMergeTool()

        // No files queued yet: the workspace shows its empty state, the rail
        // spells out the two-file minimum, and export stays disabled.
        XCTAssertTrue(element("merge.dropZone").exists, "合并工具缺少文件拖放区")
        XCTAssertTrue(element("merge.insufficientHint").exists, "缺少「至少选择两个文件」提示")
        XCTAssertFalse(element("merge.fileList").exists, "空队列不应出现文件列表")

        let export = element("workspace.primaryAction")
        XCTAssertTrue(export.waitForExistence(timeout: 5), "缺少主操作按钮")
        XCTAssertFalse(export.isEnabled, "文件不足两个时导出按钮必须禁用")
    }

    func testMergeWorkspaceHeaderAndSummaryAreRendered() {
        XCTAssertTrue(
            text("Built-in demo PDF").waitForExistence(timeout: 15),
            app.debugDescription
        )

        switchToMergeTool()

        XCTAssertTrue(text("Merge PDF Files").exists, "合并视图缺少标题")
        XCTAssertTrue(
            text("Arrange the files, then export one combined PDF.").exists,
            "合并视图缺少副标题"
        )
        XCTAssertTrue(element("merge.summary").exists, "合并视图缺少统计标签")
    }

    func testMergeExportButtonReadsMergedWhenToolIsSelected() {
        XCTAssertTrue(
            text("Built-in demo PDF").waitForExistence(timeout: 15),
            app.debugDescription
        )

        switchToMergeTool()

        // The rail's primary action renames itself per selected tool; on the
        // merge tool it must offer the merged export, not the booklet one.
        let export = element("workspace.primaryAction")
        XCTAssertTrue(export.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(
            text("Export Merged PDF").exists,
            "合并工具下主按钮应为「Export Merged PDF」。\(app.debugDescription)"
        )
        XCTAssertFalse(text("Export Booklet PDF").exists, "合并工具下不应残留小册子导出按钮")
    }

    func testMergeSettingsPanelTracksTheSelectedTool() {
        XCTAssertTrue(
            text("Built-in demo PDF").waitForExistence(timeout: 15),
            app.debugDescription
        )

        switchToMergeTool()

        XCTAssertTrue(
            text("Merge Settings").exists,
            "合并工具应在侧栏显示合并设置。\(app.debugDescription)"
        )
        XCTAssertFalse(
            text("Booklet Settings").exists,
            "合并工具下不应残留小册子设置。\(app.debugDescription)"
        )
        XCTAssertTrue(element("merge.settingsCard").exists, "缺少合并结果卡片")
    }

    func testMergeInterfaceFollowsSystemLanguage() {
        XCTAssertTrue(
            text("Built-in demo PDF").waitForExistence(timeout: 15),
            app.debugDescription
        )

        switchToMergeTool()
        XCTAssertTrue(text("Merge Settings").exists, app.debugDescription)

        app.terminate()
        launchApp(language: "zh-Hans", locale: "zh_CN")
        XCTAssertTrue(
            text("内置演示 PDF").waitForExistence(timeout: 15),
            app.debugDescription
        )

        switchToMergeTool()

        // Regression guard: merge strings must resolve in the plugin catalog.
        // A missing key silently falls back to the English source text, which
        // is exactly the "英文漏进中文界面" bug this suite is here to catch.
        XCTAssertTrue(text("合并 PDF 文件").exists, "合并视图标题未本地化")
        XCTAssertTrue(text("合并设置").exists, "侧栏合并设置未本地化")
        XCTAssertFalse(
            text("Merge Settings").exists,
            "中文界面错误显示英文「Merge Settings」。\(app.debugDescription)"
        )
    }
}
#endif
