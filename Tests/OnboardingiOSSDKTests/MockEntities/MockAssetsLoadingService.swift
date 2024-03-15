//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 03.02.2024.
//

import UIKit
@testable import OnboardingiOSSDK

final class MockAssetsLoadingService: AssetsLoadingServiceProtocol {
    
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
    
    func cacheImage(_ image: UIImage, withName name: String) { }
    func getCachedImageWith(name: String) -> UIImage? {
        nil
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
