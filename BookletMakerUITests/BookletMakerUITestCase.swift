import XCTest

class BookletMakerUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        launchApp(language: "en", locale: "en_US")
    }

    func launchApp(language: String, locale: String) {
        app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(\(language))", "-AppleLocale", locale,
            "-ApplePersistenceIgnoreState", "YES",
        ]
        app.launch()
        #if os(macOS)
        app.activate()
        // activate() 是异步的：被测 app 未到前台时，对后台窗口控件的首次
        // 点击只会把窗口激活而不送达控件（交互静默失败）。等待其真正
        // 成为 frontmost 后再做任何交互。
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline,
              NSWorkspace.shared.frontmostApplication?.bundleIdentifier != "com.coffic.bookletmaker" {
            Thread.sleep(forTimeInterval: 0.2)
        }
        openMainWindowIfNeeded()
        #endif
    }

    #if os(macOS)
    private func openMainWindowIfNeeded() {
        // WindowGroup 启动即创建唯一主窗口，这里只等待其出现，不做任何
        // 菜单交互：点击 Window 菜单与 AX 快照存在竞态——快照会把已打开的
        // 菜单收起，随后点击 menu item 时 XCTest 等待永不到来的 menu open
        // notification 而超时（"Failed to timed out while waiting for menu
        // open notification"），高负载全量跑时必现。
        // 后续点击窗口内元素（如工具栏齿轮）会自动把主窗口激活为 key。
        _ = app.windows.matching(
            NSPredicate(
                format: "identifier == %@ OR title == %@",
                "booklet-maker.main-AppWindow-1",
                "BookletMaker"
            )
        ).firstMatch.waitForExistence(timeout: 5)
    }

    // MARK: - Settings Window

    /// 设置窗口（`Window(id:)` 的 scene id 即窗口级 AX identifier）。
    ///
    /// 注意不要把 identifier 打在设置**内容视图**上：SwiftUI 会把它下推到
    /// 每个叶子元素，`firstMatch` 会命中 app 图标等叶子，其 descendants 恒为空。
    var settingsWindow: XCUIElement {
        app.windows.matching(identifier: "booklet-maker.settings").firstMatch
    }

    /// 工具栏「设置」齿轮按钮：实际 AX label 是系统图标名或工具栏标题（随语言变化）。
    private var gearButton: XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "label IN %@", ["齿轮形状", "Gear Shape", "设置", "gearshape", "Settings"])
        ).firstMatch
    }

    /// 打开设置窗口（点击主窗口工具栏齿轮；同时把已打开的设置窗口带到前台）。
    ///
    /// 不用 ⌘,：该命令携带 `entryID=general` 深链，会把选中态重置到「通用」，
    /// 使「关闭重开后保持选中」类断言失效。
    func openSettings(file: StaticString = #filePath, line: UInt = #line) {
        let gear = gearButton
        XCTAssertTrue(
            gear.waitForExistence(timeout: 15),
            "工具栏缺少设置按钮（齿轮）。\(app.debugDescription)",
            file: file,
            line: line
        )
        gear.click()
        if !settingsWindow.waitForExistence(timeout: 5) {
            // 首击可能被前台切换吞掉（只激活窗口不送达控件）；齿轮点击
            // 是幂等的 openWindow，重试一次。
            gear.click()
        }
        XCTAssertTrue(
            settingsWindow.waitForExistence(timeout: 10),
            "设置窗口未打开。\(app.debugDescription)",
            file: file,
            line: line
        )
    }

    /// 关闭设置窗口（⌘W），失败时退回窗口关闭按钮。
    ///
    /// ⌘W 只在设置窗口为 key window 时有效（本文件的调用点在关闭前都刚与
    /// 设置窗口交互过）；兜底路径参照 KuzeeUITestCase。
    func closeSettings(file: StaticString = #filePath, line: UInt = #line) {
        guard settingsWindow.waitForExistence(timeout: 5) else {
            XCTFail("设置窗口不存在，无法关闭。\(app.debugDescription)", file: file, line: line)
            return
        }

        app.typeKey("w", modifierFlags: .command)
        if settingsWindow.waitForNonExistence(timeout: 5) { return }

        // ⌘W 未生效：直接点窗口关闭按钮（AX 树中为窗口的直接子元素）。
        let closeButtonCandidates = [
            settingsWindow.buttons.matching(identifier: "_XCUI:CloseWindow").firstMatch,
            settingsWindow.buttons.matching(identifier: "AXCloseButton").firstMatch,
            settingsWindow.buttons["Close"],
            settingsWindow.buttons["关闭"],
        ]
        guard let closeButton = closeButtonCandidates.first(where: { $0.waitForExistence(timeout: 2) }) else {
            XCTFail("设置窗口没有可用的关闭按钮。\(app.debugDescription)", file: file, line: line)
            return
        }
        closeButton.click()
        XCTAssertTrue(
            settingsWindow.waitForNonExistence(timeout: 10),
            "设置窗口未关闭。\(app.debugDescription)",
            file: file,
            line: line
        )
    }

    /// 设置窗口内的文本（label OR value），限定在设置窗口作用域内查询。
    func settingsText(_ value: String) -> XCUIElement {
        settingsWindow.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@ OR value == %@", value, value))
            .firstMatch
    }

    /// 设置窗口内匹配 label 或 value 包含指定子串的元素。
    ///
    /// macOS AX 树中 StaticText 的文本暴露为 value（而非 label），
    /// 因此两个属性都要匹配。
    func settingsTextContaining(_ substring: String) -> XCUIElement {
        settingsWindow.descendants(matching: .any)
            .matching(
                NSPredicate(
                    format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@",
                    substring,
                    substring
                )
            )
            .firstMatch
    }

    /// 设置窗口内的按钮（侧边栏条目、筛选段等），按标题定位。
    ///
    /// 侧边栏条目不带 accessibility identifier；Button 的 AX label 可能拼接了
    /// SF Symbol 图标名，因此用 label == / identifier == / label CONTAINS
    /// 三重匹配兜底。
    func settingsButton(_ title: String) -> XCUIElement {
        settingsWindow.buttons.matching(
            NSPredicate(
                format: "label == %@ OR identifier == %@ OR label CONTAINS %@",
                title,
                title,
                title
            )
        ).firstMatch
    }

    /// 点击设置窗口内的元素，未命中（Not hittable）时先激活设置窗口再重试。
    ///
    /// Not hittable 的两种瞬态：设置窗口打开动画未结束、或主窗口恰好盖在
    /// 设置窗口上（点击坐标归属别的窗口）。点设置窗口几何中心可激活/前置
    /// 它（中心落在详情区非交互区域，无副作用）。
    func clickSetting(_ element: XCUIElement) {
        let deadline = Date().addingTimeInterval(8)
        while Date() < deadline {
            if element.exists && element.isHittable {
                element.click()
                return
            }
            if settingsWindow.exists, settingsWindow.isHittable {
                settingsWindow.click()
            }
            Thread.sleep(forTimeInterval: 0.4)
        }
        // 兜底：交由 XCTest 输出原始错误与诊断。
        element.click()
    }
    #endif

    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: identifier)
            .firstMatch
    }

    func text(_ value: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@ OR value == %@", value, value))
            .firstMatch
    }

    func isOn(_ element: XCUIElement) -> Bool {
        if let value = element.value as? NSNumber {
            return value.boolValue
        }
        return ["1", "selected", "on"].contains(
            (element.value as? String)?.lowercased() ?? ""
        )
    }
}

extension XCUIElement {
    func waitForValue(_ expectedValue: String, timeout: TimeInterval) -> String? {
        let predicate = NSPredicate(format: "label == %@", expectedValue)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        _ = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return exists ? label : nil
    }
}
