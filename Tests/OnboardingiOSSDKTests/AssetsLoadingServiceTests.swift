//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 20.01.2024.
//

import XCTest
@testable import OnboardingiOSSDK

final class AssetsLoadingServiceTests: XCTestCase {
    
    private let mockImage = UIImage(named: "Circle_off", in: .module, with: nil)!
    private var loader: MockAssetDataLoader!
    private var storage: MockAssetsStorage!
    private var cacheStorage: MockImagesCacheStorage!
    private var assetsLoadingService: AssetsLoadingService!
    
    override func setUp() async throws {
        loader = MockAssetDataLoader(imageToDataBlock: convertImageToData(_:))
        storage = MockAssetsStorage()
        cacheStorage = MockImagesCacheStorage()
        assetsLoadingService = AssetsLoadingService(loader: loader, storage: storage, cacheStorage: cacheStorage)
        assetsLoadingService?.clear()
    }
    
    override func tearDown() async throws {
        loader.imageToReturn = nil
        assetsLoadingService?.clear()
    }
    
    func testNormalLoading() async throws {
        loader.imageToReturn = mockImage
        let url: URL = getMockURL()
        let sourceKey = url.absoluteString
        let image = await assetsLoadingService.loadImage(from: sourceKey)
        XCTAssertTrue(compareImages(image!, mockImage))
        XCTAssertNotNil(storage.getStoredAssetData(for: sourceKey, assetType: .image))
        XCTAssertEqual(image, cacheStorage.getCachedImage(for: sourceKey))
    }
    
    func testLoadingImageMultipleTimeFromSameSource() async throws {
        loader.imageToReturn = mockImage
        let url: URL = getMockURL()
        let sourceKey = url.absoluteString

        let image = await assetsLoadingService.loadImage(from: sourceKey)
        let image2 = await assetsLoadingService.loadImage(from: sourceKey)
        let image3 = await assetsLoadingService.loadImage(from: sourceKey)
        XCTAssertEqual(image, image2)
        XCTAssertEqual(image3, image2)
        XCTAssertEqual(1, loader.callsCounter)
    }
    
    func testLoadImagesFromDifferentSources() async throws {
        loader.imageToReturn = mockImage
        let url: URL = getMockURL(id: 0)
        let sourceKey = url.absoluteString
        let _ = await assetsLoadingService.loadImage(from: sourceKey)
        
        let source2: URL = getMockURL(id: 1)
        let sourceKey2 = source2.absoluteString
        let _ = await assetsLoadingService.loadImage(from: sourceKey2)
        
        
        XCTAssertNotNil(storage.getStoredAssetData(for: sourceKey, assetType: .image))
        XCTAssertNotNil(storage.getStoredAssetData(for: sourceKey2, assetType: .image))
        XCTAssertNotNil(cacheStorage.getCachedImage(for: sourceKey))
        XCTAssertNotNil(cacheStorage.getCachedImage(for: sourceKey2))
        XCTAssertEqual(2, storage.cache.count)
        XCTAssertEqual(2, cacheStorage.cache.count)
        XCTAssertEqual(2, loader.callsCounter)
    }
    
    func testImageAlreadyCached() async {
        let url: URL = getMockURL()
        let sourceKey = url.absoluteString
        cacheStorage.cache(image: mockImage, forKey: sourceKey)
        let image = await assetsLoadingService.loadImage(from: sourceKey)
        XCTAssertEqual(image, mockImage)
        XCTAssertEqual(0, loader.callsCounter)
    }
    
    func testImageAlreadyStored() async {
        let url: URL = getMockURL()
        let sourceKey = url.absoluteString
        let imageData = convertImageToData(mockImage)
        storage.storeAssetData(imageData, for: sourceKey, assetType: .image)
        let image = await assetsLoadingService.loadImage(from: sourceKey)
        XCTAssertTrue(compareImages(image!, mockImage))
        XCTAssertNotNil(cacheStorage.getCachedImage(for: sourceKey))
        XCTAssertEqual(0, loader.callsCounter)
    }
}

// MARK: - Private methods
private extension AssetsLoadingServiceTests {
    func convertImageToData(_ image: UIImage) -> Data {
        image.pngData()!
    }
    
    func compareImages(_ image1: UIImage, _ image2: UIImage) -> Bool {
        let data1 = convertImageToData(image1)
        let data2 = convertImageToData(image2)
        return data1 == data2
    }
    
    func getMockURL(id: Int = 0) -> URL {
        URL(string: "https://ud.me/\(id)")!
    }
}

fileprivate final class MockAssetDataLoader: AssetDataLoader {
   
    var imageToReturn: UIImage?
    var imageToDataBlock: (UIImage)->(Data)
    var callsCounter = 0
    
    init(imageToReturn: UIImage? = nil, imageToDataBlock: @escaping (UIImage) -> Data) {
        self.imageToReturn = imageToReturn
        self.imageToDataBlock = imageToDataBlock
    }
    
    func loadAssetDataFrom(url: URL) async throws -> Data {
        callsCounter += 1
        if let imageToReturn {
            return imageToDataBlock(imageToReturn)
        }
        throw NSError()
    }
}

fileprivate final class MockAssetsStorage: AssetsStorageProtocol {
    var cache: [String : Data] = [:]

    func assetURLIfExist(for key: String, assetType: OnboardingiOSSDK.StoredAssetType) -> URL? {
        nil
    }
    
    func getStoredAssetData(for key: String, assetType: OnboardingiOSSDK.StoredAssetType) -> Data? {
        cache[assetType.pathForStoredAssetAtKey(key)]
    }
    
    func storeAssetData(_ data: Data, for key: String, assetType: OnboardingiOSSDK.StoredAssetType) {
        cache[assetType.pathForStoredAssetAtKey(key)] = data
    }
    
    func clearStoredAssets() {
        cache.removeAll()
    }
}

fileprivate final class MockImagesCacheStorage: ImagesCacheStorageProtocol {
    var cache: [String : UIImage] = [:]
    
    func getCachedImage(for key: String) -> UIImage? {
        cache[key]
    }
    
    func cache(image: UIImage, forKey key: String) {
        cache[key] = image
    }
    
    func clearCache() {
        cache.removeAll()
    }
}

fileprivate extension CGSize {
    var maxSide: CGFloat {
        max(width, height)
    }
}
