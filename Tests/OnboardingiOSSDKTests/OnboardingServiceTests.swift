//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 03.02.2024.
//

import Foundation
import XCTest
import ScreensGraph
@testable import OnboardingiOSSDK

final class OnboardingServiceTests: XCTestCase {
    
    private var screenGraph: ScreensGraph!
    private var assetsLoadingService: MockAssetsLoadingService!
    private var windowManager: MockOnboardingWindowManager!
    private var onboardingService: OnboardingService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        assetsLoadingService = MockAssetsLoadingService()
        AssetsLoadingService.shared = assetsLoadingService
        screenGraph = try TestsFilesHolder.shared.loadScreenGraph()
        windowManager = await MockOnboardingWindowManager()
        onboardingService = OnboardingService(windowManager: windowManager)
    }
    
    func testDefaultAppearanceMode() {
        XCTAssertNil(windowManager.window.rootViewController)
        onboardingService.startOnboarding(configuration: .init(screenGraph: screenGraph,
                                                               appearance: .default,
                                                               launchWithAnimation: false),
                                          finishedCallback: { _ in })
        XCTAssertNotNil(windowManager.window.rootViewController)
    }
    
    func testCustomWindowAppearanceMode() {
        let window = UIWindow()
        XCTAssertNil(windowManager.window.rootViewController)
        onboardingService.startOnboarding(configuration: .init(screenGraph: screenGraph,
                                                               appearance: .window(window),
                                                               launchWithAnimation: false),
                                          finishedCallback: { _ in })
        XCTAssertNil(windowManager.window.rootViewController)
        XCTAssertNotNil(window.rootViewController)
    }
    
    @MainActor
    func testPresentInVCAppearanceMode() {
        let window = UIWindow()
        window.makeKeyAndVisible()
        let vc = UIViewController()
        window.rootViewController = vc
        XCTAssertNil(windowManager.window.rootViewController)
        onboardingService.startOnboarding(configuration: .init(screenGraph: screenGraph,
                                                               appearance: .presentIn(vc),
                                                               launchWithAnimation: false),
                                          finishedCallback: { _ in })
        XCTAssertNil(windowManager.window.rootViewController)
        XCTAssertNotNil(vc.presentedViewController)
    }
    
    @MainActor
    func testDefaultLoadingScreenAppears() async {
        onboardingService.assetsPrefetchMode = .waitForAllDone
        onboardingService.startOnboarding(configuration: .init(screenGraph: screenGraph,
                                                               appearance: .default,
                                                               launchWithAnimation: false),
                                          finishedCallback: { _ in })
        XCTAssertTrue(getRootViewController() is ScreenLoadingAssetsVC)
        await Task.sleep(seconds: 0.3)
        XCTAssertFalse(getRootViewController() is ScreenLoadingAssetsVC)
    }
    
    @MainActor
    func testCustomLoadingScreenAppears() async {
        let customLoadingVC = UIViewController()
        onboardingService.assetsPrefetchMode = .waitForAllDone
        onboardingService.customLoadingViewController = customLoadingVC
        onboardingService.startOnboarding(configuration: .init(screenGraph: screenGraph,
                                                               appearance: .default,
                                                               launchWithAnimation: false),
                                          finishedCallback: { _ in })
        XCTAssertEqual(getRootViewController(), customLoadingVC)
        await Task.sleep(seconds: 0.3)
        XCTAssertNotEqual(getRootViewController(), customLoadingVC)
    }
    
}

// MARK: - Private methods
private extension OnboardingServiceTests {
    func getRootViewController() -> UIViewController? {
        guard let nav = windowManager.window.rootViewController as? OnboardingNavigationController else {
            fatalError("Root view controller is nil")
        }
        
        return nav.viewControllers.first
    }
}

final class MockOnboardingWindowManager: OnboardingWindowManagerProtocol {
    private(set) var window: UIWindow = UIWindow()
    
    @MainActor
    init() { }
    
    func getWindows() -> [UIWindow] {
        [window]
    }
    
    func getActiveWindow() -> UIWindow? {
        window
    }
    
    func getCurrentWindow() -> UIWindow? {
        window
    }
    
    func setNewRootViewController(_ viewController: UIViewController, in window: UIWindow, animated: Bool, completion: (() -> ())?) {
        window.rootViewController = viewController
    }
}
