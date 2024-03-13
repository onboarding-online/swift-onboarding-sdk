//
//  File.swift
//  
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import UIKit
import AVFoundation

typealias ImageLoadingServiceResult = Result<UIImage, AssetLoadingError>
typealias ImageLoadingServiceResultCallback = (ImageLoadingServiceResult) -> ()

typealias AssetDataLoadingResult = Result<Data, AssetLoadingError>
typealias AssetDataLoadingResultCallback = (AssetDataLoadingResult) -> ()


// MARK: - ImageLoadingServiceProtocol
protocol AssetsLoadingServiceProtocol {
    func loadImage(from url: String) async -> UIImage?
    func loadData(from url: String, assetType: StoredAssetType) async -> Data?
    func urlToStoredData(from url: String, assetType: StoredAssetType) -> URL?
    func clear()
}

// MARK: - ImageLoadingService
final class AssetsLoadingService {
    
    static var shared: AssetsLoadingServiceProtocol = AssetsLoadingService()
    
    private let serialQueue =  DispatchQueue(label: "OnboardingAssetsServiceQueue")
    private let loader: AssetDataLoader
    private let storage: AssetsStorageProtocol
    private let cacheStorage: ImagesCacheStorageProtocol
    
    private var currentAsyncProcess = [String : Task<Data?, Never>]()

    init(loader: AssetDataLoader = DefaultAssetDataLoader(),
         storage: AssetsStorageProtocol = AssetsStorage(),
         cacheStorage: ImagesCacheStorageProtocol = ImagesCacheStorage()) {
        self.loader = loader
        self.storage = storage
        self.cacheStorage = cacheStorage
    }
}

// MARK: - ImageLoadingServiceProtocol
extension AssetsLoadingService: AssetsLoadingServiceProtocol {
    func loadImage(from url: String) async -> UIImage? {
        let key = url
        if let cachedImage = cacheStorage.getCachedImage(for: key) {
            OnboardingLogger.logInfo(topic: .assetsPrefetch, "Will return cached image for key: \(key)")
            return cachedImage
        }
        
        if let imageData = await loadData(from: url, assetType: .image),
           var image = await createImage(from: imageData) {
            if #available(iOS 15.0, *) {
                let preparedImage = await image.byPreparingForDisplay()
                image = preparedImage ?? image
            }
            self.cacheStorage.cache(image: image, forKey: url)
            return image
        }
        
        return nil
    }
    
    func loadData(from url: String,
                  assetType: StoredAssetType) async -> Data? {
        let key = url
        
        // Check if process already in progress
        if let dataTask = serialQueue.sync(execute: { currentAsyncProcess[key] }) {
            OnboardingLogger.logInfo(topic: .assetsPrefetch, "Will return active data loading task for key: \(key)")
            return await dataTask.value
        }
        
        guard let assetURL = URL(string: url) else {
            return nil
        }
        
        let task: Task<Data?, Never> = Task.detached(priority: .medium) {
            if let storedData = self.storage.getStoredAssetData(for: key, assetType: assetType) {
                OnboardingLogger.logInfo(topic: .assetsPrefetch, "Will return stored data for key: \(key)")
                return storedData
            }
            
            if let assetData = try? await self.loadAssetData(from: assetURL) {
                self.storage.storeAssetData(assetData, for: key, assetType: assetType)
                OnboardingLogger.logInfo(topic: .assetsPrefetch, "Will return loaded data for key: \(key)")
                return assetData
            } else {
                return nil
            }
        }
        
        serialQueue.sync { currentAsyncProcess[key] = task }
        let data = await task.value
        serialQueue.sync { currentAsyncProcess[key] = nil }
        
        return data
    }
 
    func getThumbnailImage(forUrl url: URL) -> UIImage? {
        let asset: AVAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch { }
        
        return nil
    }
    
    func urlToStoredData(from url: String, assetType: StoredAssetType) -> URL? {
        storage.assetURLIfExist(for: url, assetType: assetType)
    }
    
    func clear() {
        storage.clearStoredAssets()
        cacheStorage.clearCache()
    }
}

// MARK: - Private methods
fileprivate extension AssetsLoadingService {
    func loadAssetData(from url: URL) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    let imageData = try await self.loader.loadAssetDataFrom(url: url)
                    continuation.resume(returning: imageData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func createImage(from imageData: Data) async -> UIImage? {
        await UIImage.createFrom(imageData: imageData)
    }
}

enum AssetLoadingError: String, LocalizedError {
    case invalidAssetURL
    case invalidAssetData
    case failedToLoadAsset
    
    public var errorDescription: String? {
        rawValue
    }
}
