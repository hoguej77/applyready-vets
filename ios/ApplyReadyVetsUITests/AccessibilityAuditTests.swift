import XCTest

final class AccessibilityAuditTests: XCTestCase {
    @MainActor
    func testWelcomeAndFirstWorkflowScreenPassAutomatedAccessibilityAudit() throws {
        let app = launchApp()
        XCTAssertTrue(
            app.buttons["Get started"].waitForExistence(timeout: 10),
            "The welcome screen did not become ready."
        )
        try app.performAccessibilityAudit()
        keepScreenshot(named: "Welcome")

        app.buttons["Explore with safe demo data"].tap()
        XCTAssertTrue(
            app.navigationBars["Import"].waitForExistence(timeout: 10),
            "The first workflow screen did not become ready."
        )
        try app.performAccessibilityAudit()

        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(
            app.navigationBars["Today"].waitForExistence(timeout: 10),
            "The personalized Today screen did not become ready."
        )
        try app.performAccessibilityAudit()
        keepScreenshot(named: "Today")
    }

    @MainActor
    func testWelcomeSupportsLargestDynamicTypeWithoutHidingLegalNotice() throws {
        let app = launchApp(
            contentSizeCategory: "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
        )
        XCTAssertTrue(
            app.buttons["Get started"].waitForExistence(timeout: 10),
            "The primary action was unavailable at the largest Dynamic Type size."
        )
        XCTAssertTrue(
            app.buttons["Explore with safe demo data"].isHittable,
            "The secondary action was not reachable at the largest Dynamic Type size."
        )
        try app.performAccessibilityAudit()

        let notice = app.staticTexts.matching(
            NSPredicate(
                format: "label CONTAINS[c] %@",
                "Independent product"
            )
        ).firstMatch
        XCTAssertTrue(notice.waitForExistence(timeout: 5))
        let welcomeScrollView = app.scrollViews.firstMatch
        for _ in 0..<12 where !notice.isHittable {
            if welcomeScrollView.exists {
                welcomeScrollView.swipeUp()
            } else {
                app.swipeUp()
            }
        }
        XCTAssertTrue(
            notice.isHittable,
            "The non-affiliation and no-guarantee notice could not be reached at the largest Dynamic Type size."
        )
        keepScreenshot(named: "Welcome-Largest-Dynamic-Type")
    }

    @MainActor
    func testTodaySupportsLargestDynamicTypeWithReachablePrimaryAction() throws {
        let app = launchApp(
            contentSizeCategory: "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
        )
        XCTAssertTrue(
            app.buttons["Explore with safe demo data"].waitForExistence(timeout: 10),
            "The safe demo action was unavailable at the largest Dynamic Type size."
        )
        app.buttons["Explore with safe demo data"].tap()

        let today = app.tabBars.buttons["Today"]
        XCTAssertTrue(today.waitForExistence(timeout: 10))
        today.tap()

        let workspace = app.buttons["Open workspace"]
        XCTAssertTrue(
            workspace.waitForExistence(timeout: 10),
            "Today did not expose its primary next action at the largest Dynamic Type size."
        )
        let todayScrollView = app.scrollViews.firstMatch
        for _ in 0..<8 where !workspace.isHittable {
            if todayScrollView.exists {
                todayScrollView.swipeUp()
            } else {
                app.swipeUp()
            }
        }
        XCTAssertTrue(
            workspace.isHittable,
            "Today’s primary next action could not be reached at the largest Dynamic Type size."
        )
        try app.performAccessibilityAudit()
        keepScreenshot(named: "Today-Largest-Dynamic-Type")
    }

    @MainActor
    func testTopLevelTabsKeepNativeLabelsAndAccessibleDestinations() throws {
        let app = launchApp()
        app.buttons["Explore with safe demo data"].tap()

        let destinations: [(tab: String, title: String)] = [
            ("Today", "Today"),
            ("Workspace", "Import"),
            ("Applications", "Applications"),
            ("Toolkit", "Toolkit"),
        ]
        for destination in destinations {
            let tab = app.tabBars.buttons[destination.tab]
            XCTAssertTrue(
                tab.waitForExistence(timeout: 10),
                "The \(destination.tab) tab did not have a stable, accessible label."
            )
            tab.tap()
            XCTAssertTrue(
                app.navigationBars[destination.title].waitForExistence(timeout: 10),
                "The \(destination.tab) tab did not open its expected destination."
            )
            try app.performAccessibilityAudit(for: [.dynamicType, .hitRegion])
        }
    }

    @MainActor
    func testToolkitOpensPrivateHeadshotStudio() throws {
        let app = launchApp()
        app.buttons["Explore with safe demo data"].tap()

        let toolkit = app.tabBars.buttons["Toolkit"]
        XCTAssertTrue(toolkit.waitForExistence(timeout: 10))
        toolkit.tap()

        let headshotStudio = app.staticTexts["Headshot studio"].firstMatch
        XCTAssertTrue(
            headshotStudio.waitForExistence(timeout: 10),
            "Toolkit did not expose the headshot studio."
        )
        headshotStudio.tap()
        XCTAssertTrue(
            app.navigationBars["Headshot studio"].waitForExistence(timeout: 10),
            "Headshot studio did not open."
        )
        XCTAssertTrue(
            app.staticTexts["A better headshot starts with you"].waitForExistence(timeout: 10),
            "Headshot studio did not explain how to select a source photo."
        )
        try app.performAccessibilityAudit(for: [.dynamicType, .hitRegion])
    }

    @MainActor
    func testOnboardingScreensRemainReadableAndReachable() throws {
        let app = launchApp()
        XCTAssertTrue(app.buttons["Get started"].waitForExistence(timeout: 10))
        keepScreenshot(named: "Onboarding-Welcome")
        app.buttons["Get started"].tap()

        let name = app.textFields["Preferred name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        try app.performAccessibilityAudit()
        keepScreenshot(named: "Onboarding-Profile")
        name.tap()
        name.typeText("Jordan")
        app.buttons["Onboarding.Profile.Continue"].tap()

        XCTAssertTrue(
            app.staticTexts["Choose your assistance level."].waitForExistence(timeout: 10)
        )
        try app.performAccessibilityAudit()
        keepScreenshot(named: "Onboarding-Assistance")
        app.buttons["Onboarding.Assistance.Continue"].tap()

        XCTAssertTrue(app.buttons["Enter my workspace"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit()
        keepScreenshot(named: "Onboarding-Ready")
    }

    @MainActor
    func testFilesPickerExposesBrowseSharedRecentsAndSamples() throws {
        let app = launchApp()
        XCTAssertTrue(app.buttons["Explore with safe demo data"].waitForExistence(timeout: 10))
        app.buttons["Explore with safe demo data"].tap()

        let chooseFile = app.buttons["Choose file"].firstMatch
        XCTAssertTrue(chooseFile.waitForExistence(timeout: 10))
        chooseFile.tap()
        XCTAssertTrue(
            app.navigationBars["Recents"].waitForExistence(timeout: 30) ||
                app.buttons["Browse"].waitForExistence(timeout: 10),
            "Apple's Files picker did not open."
        )
        let recents = app.buttons["Recents"]
        let shared = app.buttons["Shared"]
        let browse = app.buttons["Browse"]
        XCTAssertTrue(recents.waitForExistence(timeout: 10))
        XCTAssertTrue(shared.waitForExistence(timeout: 10))
        XCTAssertTrue(browse.waitForExistence(timeout: 10))
        browse.tap()

        let appFolder = filePickerItem(named: "ApplyReady Vets", in: app)
        if !appFolder.waitForExistence(timeout: 10) {
            let back = app.buttons["Back"].firstMatch
            if back.exists {
                back.tap()
            }
            let onMyiPhone = filePickerItem(named: "On My iPhone", in: app)
            XCTAssertTrue(
                onMyiPhone.waitForExistence(timeout: 10),
                "The Files picker did not expose the local On My iPhone location."
            )
            onMyiPhone.tap()
        }

        XCTAssertTrue(
            appFolder.waitForExistence(timeout: 30),
            "Apply Ready Vets was not exposed in On My iPhone."
        )
        appFolder.tap()

        let samples = filePickerItem(named: "Samples", in: app)
        XCTAssertTrue(
            samples.waitForExistence(timeout: 30),
            "The app-managed Samples folder was not visible."
        )
        samples.tap()

        let sampleResume = filePickerItem(named: "Sample Veteran Resume", in: app)
        XCTAssertTrue(
            sampleResume.waitForExistence(timeout: 30),
            "The sample veteran resume was not visible."
        )
        keepScreenshot(named: "Files-Samples")
        sampleResume.tap()

        XCTAssertTrue(
            app.staticTexts["Selected file: Sample Veteran Resume.txt"]
                .waitForExistence(timeout: 15),
            "The selected sample resume was not imported into Apply Ready Vets."
        )
    }

    @MainActor
    func testFreeWorkspaceBoundaryPresentsComplete() throws {
        let app = launchApp()
        completeOnboarding(in: app)
        app.tabBars.buttons["Applications"].tap()
        XCTAssertTrue(app.navigationBars["Applications"].waitForExistence(timeout: 10))
        app.buttons["Add an application"].tap()

        let employer = app.textFields["Employer"]
        XCTAssertTrue(employer.waitForExistence(timeout: 10))
        employer.tap()
        employer.typeText("Test Employer")
        let role = app.textFields["Role title"]
        role.tap()
        role.typeText("Operations Manager")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Operations Manager"].waitForExistence(timeout: 10))
        app.buttons["Add application"].tap()
        XCTAssertTrue(
            app.staticTexts["One workspace is free"].waitForExistence(timeout: 10),
            "The second-workspace boundary did not present Complete."
        )
    }

    @MainActor
    private func launchApp(
        contentSizeCategory: String? = nil
    ) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-UI_TESTING", "YES",
        ]
        if let contentSizeCategory {
            app.launchArguments += [
                "-UIPreferredContentSizeCategoryName",
                contentSizeCategory,
            ]
        }
        app.launch()
        return app
    }

    @MainActor
    private func completeOnboarding(in app: XCUIApplication) {
        let getStarted = app.buttons["Get started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 10))
        getStarted.tap()

        let name = app.textFields["Preferred name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText("Jordan")
        app.buttons["Onboarding.Profile.Continue"].tap()

        XCTAssertTrue(
            app.staticTexts["Choose your assistance level."].waitForExistence(timeout: 10)
        )
        app.buttons["Onboarding.Assistance.Continue"].tap()

        let enter = app.buttons["Enter my workspace"]
        XCTAssertTrue(enter.waitForExistence(timeout: 10))
        enter.tap()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))
    }

    @MainActor
    private func keepScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func filePickerItem(named name: String, in app: XCUIApplication) -> XCUIElement {
        let predicate = NSPredicate(
            format: "label ==[c] %@ OR label ==[c] %@ OR label BEGINSWITH[c] %@",
            name,
            "\(name), Folder",
            "\(name),"
        )
        return app.descendants(matching: .any)
            .matching(predicate)
            .firstMatch
    }
}
