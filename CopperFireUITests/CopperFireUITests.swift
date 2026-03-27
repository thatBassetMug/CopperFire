//
//  CopperFireUITests.swift
//  CopperFireUITests
//
//  Created by Amanda Basset on 3/27/26.
//

import XCTest

final class CopperFireUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch & Intro

    @MainActor
    func testIntroTextAppearsOnLaunch() throws {
        let intro = app.staticTexts["introText"]
        XCTAssertTrue(intro.waitForExistence(timeout: 3))
    }

    @MainActor
    func testClearButtonExists() throws {
        let clear = app.buttons["clearButton"]
        XCTAssertTrue(clear.waitForExistence(timeout: 3))
    }

    // MARK: - Interactions

    @MainActor
    func testTapDismissesIntroText() throws {
        let intro = app.staticTexts["introText"]
        XCTAssertTrue(intro.waitForExistence(timeout: 3))

        // Long press on the canvas area to trigger the drag gesture
        let window = app.windows.firstMatch
        window.press(forDuration: 0.5)

        // Intro should disappear after interaction
        XCTAssertTrue(intro.waitForNonExistence(timeout: 3))
    }

    @MainActor
    func testClearButtonIsTappable() throws {
        let clear = app.buttons["clearButton"]
        XCTAssertTrue(clear.waitForExistence(timeout: 3))

        // First draw something
        let window = app.windows.firstMatch
        window.press(forDuration: 0.5)

        // Tap clear — should not crash
        clear.tap()
    }

    @MainActor
    func testDragGestureDoesNotCrash() throws {
        let window = app.windows.firstMatch

        // Perform a drag across the screen
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)

        // App should still be running
        XCTAssertTrue(app.windows.firstMatch.exists)
    }

    @MainActor
    func testMultipleDragsThenClear() throws {
        let window = app.windows.firstMatch

        // Multiple drags
        for i in stride(from: 0.2, to: 0.8, by: 0.2) {
            let start = window.coordinate(withNormalizedOffset: CGVector(dx: i, dy: 0.3))
            let end = window.coordinate(withNormalizedOffset: CGVector(dx: i, dy: 0.7))
            start.press(forDuration: 0.1, thenDragTo: end)
        }

        // Clear
        let clear = app.buttons["clearButton"]
        XCTAssertTrue(clear.waitForExistence(timeout: 3))
        clear.tap()

        // App should still be responsive
        XCTAssertTrue(window.exists)
    }

    // MARK: - Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
