#if os(macOS)
import XCTest

final class BookletMakerMacWorkspaceUITests: BookletMakerUITestCase {
    /// 匹配任意一组候选文本的元素（label 或 value）。
    private func anyText(_ candidates: [String]) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label IN %@ OR value IN %@", candidates, candidates))
            .firstMatch
    }

    /// 匹配任意一组候选 label 的按钮。
    private func anyButton(_ candidates: [String]) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label IN %@", candidates)).firstMatch
    }

    func testWorkspaceAndPreviewStages() {
        // 内置演示 PDF 应已加载（文本在 value/label）。
        let demo = anyText(["Built-in demo PDF", "内置演示 PDF"])
        XCTAssertTrue(demo.waitForExistence(timeout: 15), app.debugDescription)

        // 预览区四个阶段 tab 存在，逐个点击并确认进入选中态。
        let stageIDs = [
            "booklet.preview.original",
            "booklet.preview.converted",
            "booklet.preview.before",
            "booklet.preview.after",
        ]
        for id in stageIDs {
            let tab = element(id)
            XCTAssertTrue(tab.waitForExistence(timeout: 5), "Missing preview tab \(id)")
            tab.click()
            let selected = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "value CONTAINS[c] %@", "selected"),
                object: tab
            )
            XCTAssertEqual(
                XCTWaiter.wait(for: [selected], timeout: 5),
                .completed,
                "Preview tab \(id) should become selected"
            )
        }
    }

    func testSettingsCanBeChanged() {
        let demo = anyText(["Built-in demo PDF", "内置演示 PDF"])
        XCTAssertTrue(demo.waitForExistence(timeout: 15), app.debugDescription)

        // 输出纸张切换到 A5（选中态变化）。
        let a5 = app.buttons.matching(
            NSPredicate(format: "identifier == %@ AND label == %@", "booklet.outputPaper", "A5")
        ).firstMatch
        XCTAssertTrue(a5.waitForExistence(timeout: 5), app.debugDescription)
        a5.click()
        let a5Selected = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value CONTAINS[c] %@", "selected"),
            object: a5
        )
        XCTAssertEqual(XCTWaiter.wait(for: [a5Selected], timeout: 5), .completed, "A5 should become selected")

        // 版式下拉存在。
        let layout = element("booklet.layoutPicker")
        XCTAssertTrue(layout.waitForExistence(timeout: 5), "Missing layout picker")

        // 补齐空白页与裁切标记开关存在（状态可切换或至少可交互）。
        let padBlankPage = app.checkBoxes["booklet.padBlankPage"]
        XCTAssertTrue(padBlankPage.waitForExistence(timeout: 5), "Missing pad blank page toggle")
        let cutMarks = app.checkBoxes["booklet.addCutMarks"]
        XCTAssertTrue(cutMarks.waitForExistence(timeout: 5), "Missing cut marks toggle")
        if cutMarks.isEnabled {
            let before = isOn(cutMarks)
            cutMarks.click()
            XCTAssertNotEqual(isOn(cutMarks), before, "Cut marks toggle should flip")
        }
    }

    func testSplitPlanBoundaryAndExportPanel() {
        let demo = anyText(["Built-in demo PDF", "内置演示 PDF"])
        XCTAssertTrue(demo.waitForExistence(timeout: 15), app.debugDescription)

        // 切到「拆分 PDF」工具并断言拆分视图出现。
        let splitTool = app.radioButtons.matching(
            NSPredicate(format: "label IN %@", ["Split PDF", "拆分 PDF"])
        ).firstMatch
        XCTAssertTrue(splitTool.waitForExistence(timeout: 5), app.debugDescription)
        splitTool.click()

        // 拆分视图应出现页面序列（不依赖单选按钮选中态，直接验证内容）。
        // 首击可能被窗口激活竞态吞掉（只激活不切换工具），未出现则重试。
        let pageSequence = anyText(["Page Sequence", "页面序列"])
        if !pageSequence.waitForExistence(timeout: 5) {
            splitTool.click()
        }
        XCTAssertTrue(pageSequence.waitForExistence(timeout: 10), "拆分视图缺少页面序列")
        let export = element("workspace.primaryAction")
        XCTAssertTrue(export.waitForExistence(timeout: 5), "Missing primary export action")
    }

    func testBookletExportPanelCanBeOpenedAndCancelled() {
        let demo = anyText(["Built-in demo PDF", "内置演示 PDF"])
        XCTAssertTrue(demo.waitForExistence(timeout: 15), app.debugDescription)

        let export = element("workspace.primaryAction")
        XCTAssertTrue(export.waitForExistence(timeout: 5), app.debugDescription)
        export.click()

        let panel = app.sheets.firstMatch.exists ? app.sheets.firstMatch : app.dialogs.firstMatch
        XCTAssertTrue(panel.waitForExistence(timeout: 10), "Booklet export should present a save panel")
        let cancel = panel.buttons["CancelButton"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        cancel.click()
        XCTAssertTrue(demo.exists)
    }
}
#endif
