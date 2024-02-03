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
        screenGraph = try loadScreenGraph()
        assetsPrefetchService = AssetsPrefetchService(screenGraph: screenGraph,
                                                      assetsLoadingService: assetsLoadingService)
    }
    
    private func loadScreenGraph() throws -> ScreensGraph {
        let jsonName = "onboarding-tests.json"
        let localPath = TestsFilesHolder.shared.url(for: jsonName)!
        let data = try Data(contentsOf: localPath)
        let decoder = JSONDecoder()
        let screenGraph = try decoder.decode(ScreensGraph.self, from: data)
        return screenGraph
    }
   
    func testAllAssetsFetched() async throws {
        try await assetsPrefetchService.prefetchAllAssets()
        for (id, _) in screenGraph.screens {
            XCTAssertTrue(assetsPrefetchService.isScreenAssetsPrefetched(screenId: id))
            XCTAssertFalse(assetsPrefetchService.isScreenAssetsPrefetchFailed(screenId: id))
        }
//        assetsPrefetchService.startLazyPrefetching()
//        assetsPrefetchService.isScreenAssetsPrefetched
//        assetsPrefetchService.isScreenAssetsPrefetchFailed
//        assetsPrefetchService.onScreenReady
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

private final class MockAssetsLoadingService: AssetsLoadingServiceProtocol {
    
    var responseDelay: TimeInterval?
    var shouldFail = false
    
    func loadImage(from url: String) async -> UIImage? {
        await waitForResponseDelay()
        if shouldFail {
            return nil
        }
        return .init()
    }
    
    func loadData(from url: String, assetType: OnboardingiOSSDK.StoredAssetType) async -> Data? {
        await waitForResponseDelay()
        if shouldFail {
            return nil
        }
        return Data()
    }
    
    func urlToStoredData(from url: String, assetType: OnboardingiOSSDK.StoredAssetType) -> URL? {
        return nil
    }
    
    func clear() {
        
    }
    
    private func waitForResponseDelay() async {
        await waitFor(responseDelay)
    }
    
    private func waitFor(_ seconds: TimeInterval?) async {
        guard let seconds else { return }
        
        await Task.sleep(seconds: seconds)
    }
}
