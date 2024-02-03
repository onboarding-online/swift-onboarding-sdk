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
    func loadImageFromURL(_ url: URL, intoView imageView: UIImageView, placeholderImageName: String?)
    func loadImage(from url: String) async -> UIImage?
    func loadData(from url: String, assetType: StoredAssetType) async -> Data?
    func urlToStoredData(from url: String, assetType: StoredAssetType) -> URL?
    func clear()
}

// MARK: - ImageLoadingService
final class AssetsLoadingService {
    
    public static let shared: AssetsLoadingServiceProtocol = AssetsLoadingService()
    
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
    func loadImageFromURL(_ url: URL,
                          intoView imageView: UIImageView,
                          placeholderImageName: String?) {
        
        Task { @MainActor in
            if let placeholderImageName = placeholderImageName {
                imageView.image = UIImage(named: placeholderImageName)
            }
            let urlHash = url.absoluteString.hash
            imageView.tag = urlHash
            
            let image = await loadImage(from: url.absoluteString)
            if imageView.tag == urlHash {
                if imageView.image != image {
                    imageView.setImage(image, animated: true)
                }
            }
        }
    }
  
    func loadImage(from url: String) async -> UIImage? {
        let key = url
        if let cachedImage = cacheStorage.getCachedImage(for: key) {
            OnboardingLogger.logInfo(topic: .assetsPrefetch, "Will return cached image for key: \(key)")
            return cachedImage
        }
        
        if let imageData = await loadData(from: url, assetType: .image),
           let image = await createImage(from: imageData) {
            self.cacheStorage.cache(image: image, forKey: url)
            return image
        }
        
        return nil
    }
    
    func loadData(from url: String,
                  assetType: StoredAssetType) async -> Data? {

        // Check if file is from assets
        switch assetType {
        case .image, .video:
            if let data = getPreparedAssetData(from: url,
                                               assetType: assetType) {
                return data
            }
        case .videoThumbnail:
            return nil
        }
        
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
    
    func getPreparedAssetData(from url: String,
                              assetType: StoredAssetType) -> Data? {
        switch assetType {
        case .image:
            if let imageThatAddedManuallyInProject = url.resourceName(),
               let image = UIImage.init(named: imageThatAddedManuallyInProject){
                return image.jpegData(compressionQuality: 1)
            }
        case .videoThumbnail:
            return nil
        case .video:
            if let name = url.resourceNameWithoutExtension(),
               let url = Bundle.main.url(forResource: name, withExtension: "mp4") {
                return try? Data(contentsOf: url)
            }
        }
        return nil
    }
    
    func createImage(from imageData: Data) async -> UIImage? {
        if let gif = await GIFImageCreator.shared.createGIFImageWithData(imageData) {
            return gif
        }
        return UIImage(data: imageData)
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
