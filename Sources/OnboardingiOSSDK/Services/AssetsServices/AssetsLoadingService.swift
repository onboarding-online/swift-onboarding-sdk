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
    func loadImage(from url: String, completion: @escaping ImageLoadingServiceResultCallback)
    func loadData(from url: String, assetType: StoredAssetType, completion: @escaping AssetDataLoadingResultCallback)
    func urlToStoredData(from url: String, assetType: StoredAssetType) -> URL?
    func clearStoredAssets()
}

// MARK: - ImageLoadingService
final class AssetsLoadingService {
    
    public static let shared: AssetsLoadingServiceProtocol = AssetsLoadingService()
    
    private let assetsServiceSerialQueue =  DispatchQueue(label: "OnboardingAssetsServiceQueue")
    private let assetsServiceConcurrentQueue =  DispatchQueue(label: "OnboardingAssetsServiceConcurrentQueue", qos: .userInteractive, attributes: [.concurrent])
    private let loader: AssetDataLoader
    private let storage: AssetsStorageProtocol
    private let cacheStorage: ImagesCacheStorageProtocol
    
    private var currentProcess = [String : [AssetDataLoadingResultCallback]]()
    
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
        
        if let placeholderImageName = placeholderImageName {
            imageView.image = UIImage(named: placeholderImageName)
        }
        let urlHash = url.absoluteString.hash
        imageView.tag = urlHash
        self.loadImage(from: url.absoluteString) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    if imageView.tag == urlHash {
                        if imageView.image != image {
                            imageView.setImage(image, animated: true)
                        }
                    }
                case .failure:
                    return
                }
            }
        }
    }
    
    func loadImage(from url: String,
                   completion: @escaping ImageLoadingServiceResultCallback) {
        if let cachedImage = cacheStorage.getCachedImage(for: url) {
            completion(.success(cachedImage))
            return
        }
        
        if let storedImage = getStoredImage(for: url) {
            cacheStorage.cache(image: storedImage, forKey: url)
            completion(.success(storedImage))
            return
        }
        
        if let imageThatAddedManuallyInProject = url.resourceName()  {
            if let storedImage = UIImage.init(named: imageThatAddedManuallyInProject) {
                completion(.success(storedImage))
                return
            }
        }
        
        loadData(from: url,
                 assetType: .image) { result in
            switch result {
            case .success(let imageData):
                if let image = UIImage(data: imageData) {
                    self.cacheStorage.cache(image: image, forKey: url)
                    completion(.success(image))
                } else {
                    completion(.failure(.invalidAssetData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func loadData(from url: String,
                  assetType: StoredAssetType,
                  completion: @escaping AssetDataLoadingResultCallback) {
        guard let assetURL = URL(string: url) else {
            completion(.failure(.invalidAssetURL))
            return
        }
        
        switch assetType {
        case .image:
            if let imageThatAddedManuallyInProject = url.resourceName()  {
                if UIImage.init(named: imageThatAddedManuallyInProject) != nil {
                    completion(.success(Data()))
                    return
                }
            }
            
        case .videoThumbnail:
            return
        case .video:
            if let name = url.resourceNameWithoutExtension() {
                if Bundle.main.url(forResource: name, withExtension: "mp4") != nil {
                    completion(.success(Data()))
                    return
                }
            }
        }
        
        assetsServiceSerialQueue.async { [unowned self] in
            let processUrl = url + assetType.pathExtension
            if let data = storage.getStoredAssetData(for: url, assetType: assetType) {
                completion(.success(data))
                return
            } else if self.currentProcess[processUrl] != nil {
                self.currentProcess[processUrl]?.append(completion)
                return
            } else {
                self.currentProcess[processUrl] = [completion]
            }
            
            self.assetsServiceConcurrentQueue.async { [unowned self] in
                if let assetData = fetchDataFrom(url: assetURL, assetType: assetType) {
                    self.storage.storeAssetData(assetData, for: assetURL.absoluteString, assetType: assetType)
                    self.nofiyWaitersFor(url: processUrl, withResult: .success(assetData))
                } else {
                    self.nofiyWaitersFor(url: processUrl, withResult: .failure(.failedToLoadAsset))
                }
            }
        }
    }
    
    func fetchDataFrom(url: URL, assetType: StoredAssetType) -> Data? {
        switch assetType {
        case .image, .video:
            return try? Data(contentsOf: url)
        case .videoThumbnail:
            return getThumbnailImage(forUrl: url)?.jpegData(compressionQuality: 1)
        }
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
    
    func clearStoredAssets() {
        storage.clearStoredAssets()
    }
}

// MARK: - Private methods
fileprivate extension AssetsLoadingService {
    func fetchImageFor(url: URL) async -> UIImage? {
        do {
            let imageData = try await loadAssetData(from: url)
            if let image = UIImage(data: imageData) {
                storeAndCache(imageData: imageData, image: image, forKey: url.absoluteString)
                return image
            }
            return nil
        } catch {
            return nil
        }
    }
    
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
    
    func storeAndCache(imageData: Data, image: UIImage, forKey key: String) {
        storage.storeAssetData(imageData, for: key, assetType: .image)
        cacheStorage.cache(image: image, forKey: key)
    }
    
    func nofiyWaitersFor(url: String, withResult result: AssetDataLoadingResult) {
        assetsServiceSerialQueue.async { [unowned self] in
            if let completions = self.currentProcess[url] {
                for completion in completions {
                    completion(result)
                }
            }
            self.currentProcess[url] = nil
        }
    }
    
    func getStoredImage(for url: String) -> UIImage? {
        if let storedImageData = getStoredImageData(for: url) {
            return UIImage(data: storedImageData)
        }
        return nil
    }
    
    func getStoredImageData(for url: String) -> Data? {
        storage.getStoredAssetData(for: url, assetType: .image)
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
