//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 02.02.2024.
//

import XCTest
import ScreensGraph
@testable import OnboardingiOSSDK


final class AssetsPrefetchServiceTests: XCTestCase {
    
    private var screenGraph: ScreensGraph!
    private var assetsLoadingService: MockAssetsLoadingService!
    private var assetsPrefetchService: AssetsPrefetchService!
    private let screenIdWithAssets = "screen1"
    
    override func setUp() async throws {
        assetsLoadingService = MockAssetsLoadingService()
        AssetsLoadingService.shared = assetsLoadingService
        screenGraph = try TestsFilesHolder.shared.loadScreenGraph()
        assetsPrefetchService = AssetsPrefetchService(screenGraph: screenGraph)
    }
    
    func testAllAssetsFetched() async throws {
        try await assetsPrefetchService.prefetchAllAssets()
        for (id, _) in screenGraph.screens {
            XCTAssertTrue(assetsPrefetchService.isScreenAssetsPrefetched(screenId: id))
            XCTAssertFalse(assetsPrefetchService.isScreenAssetsPrefetchFailed(screenId: id))
        }
    }
    
    func testAllAssetsFailed() async throws {
        assetsLoadingService.shouldFail = true
        try? await assetsPrefetchService.prefetchAllAssets()
        for (id, _) in screenGraph.screens {
            if id == screenIdWithAssets {
                XCTAssertFalse(assetsPrefetchService.isScreenAssetsPrefetched(screenId: id))
                XCTAssertTrue(assetsPrefetchService.isScreenAssetsPrefetchFailed(screenId: id))
            } else {
                XCTAssertTrue(assetsPrefetchService.isScreenAssetsPrefetched(screenId: id))
                XCTAssertFalse(assetsPrefetchService.isScreenAssetsPrefetchFailed(screenId: id))
            }
        }
    }
    
    func testLazyPrefetch() async throws {
        assetsLoadingService.responseDelay = 0.3
        assetsPrefetchService.startLazyPrefetching()
        try await assetsPrefetchService.onScreenReady(screenId: screenIdWithAssets)
    }
    
    func testLazyPrefetchFailed() async {
        assetsLoadingService.shouldFail = true
        assetsLoadingService.responseDelay = 0.3
        assetsPrefetchService.startLazyPrefetching()
        do {
            try await assetsPrefetchService.onScreenReady(screenId: screenIdWithAssets)
            fatalError("On screen should throw error")
        } catch { }
    }
    
    func testLazyPrefetchFailedAfterTimeout() async throws {
        assetsLoadingService.shouldFail = true
        assetsLoadingService.responseDelay = 0.3
        assetsPrefetchService.startLazyPrefetching()
        try await assetsPrefetchService.onScreenReady(screenId: screenIdWithAssets, timeout: 0.1)
    }
    
}
