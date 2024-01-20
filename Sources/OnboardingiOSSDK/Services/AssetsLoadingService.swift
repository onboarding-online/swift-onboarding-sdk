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
    func loadImage(from url: String, assetType: StoredAssetType, completion: @escaping ImageLoadingServiceResultCallback)
    func loadData(from url: String, assetType: StoredAssetType, completion: @escaping AssetDataLoadingResultCallback)
}

// MARK: - ImageLoadingService
final class AssetsLoadingService {
    
    public static let shared = AssetsLoadingService()
   
    private let assetsServiceSerialQueue =  DispatchQueue(label: "OnboardingAssetsServiceQueue")
    private let assetsServiceConcurrentQueue =  DispatchQueue(label: "OnboardingAssetsServiceConcurrentQueue", qos: .userInteractive, attributes: [.concurrent])
    private let imageCache = NSCache<NSString, UIImage>()
    private let storage = AssetsStorage()

    private var currentProcess = [String : [AssetDataLoadingResultCallback]]()
    
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
                   assetType: StoredAssetType = .image,
                   completion: @escaping ImageLoadingServiceResultCallback) {
        if let cachedImage = self.imageCache.object(forKey: url as NSString) {
            completion(.success(cachedImage))
            return
        }
        
        if let storedImage = getStoredImage(for: url) {
            self.imageCache.setObject(storedImage, forKey: url as NSString)
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
                 assetType: assetType) { result in
            switch result {
            case .success(let imageData):
                if let image = UIImage(data: imageData) {
                    self.imageCache.setObject(image, forKey: url as NSString)
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
    
    public func clearStoredAssets() {
        storage.clearStoredAssets()
    }
}

// MARK: - Private methods
fileprivate extension AssetsLoadingService {
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
