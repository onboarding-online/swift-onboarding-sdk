//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 20.01.2024.
//

import XCTest
@testable import OnboardingiOSSDK

final class AssetsStorageServiceTests: XCTestCase {
    
    private var fileManager: MockFileManager!
    private var assetsStorage: AssetsStorage!
    
    override func setUp() async throws {
        try await super.setUp()
        
        fileManager = MockFileManager()
        assetsStorage = AssetsStorage(fileManager: fileManager)
    }
    
    func testAssetNotExist() throws {
        StoredAssetType.allCases.forEach { assetType in
            XCTAssertNil(assetsStorage.assetURLIfExist(for: "1", assetType: assetType))
        }
    }
    
    func testAssetsStored() {
        let key = "1"
        StoredAssetType.allCases.forEach { assetType in
            assetsStorage.storeAssetData(Data(), for: key, assetType: assetType)
            XCTAssertNotNil(assetsStorage.assetURLIfExist(for: key, assetType: assetType))
        }
    }
    
    func testMultipleAssetsStored() {
        let keys = ["1", "a", "-", "/"]
        StoredAssetType.allCases.forEach { assetType in
            for key in keys {
                assetsStorage.storeAssetData(Data(), for: key, assetType: assetType)
            }
        }
        StoredAssetType.allCases.forEach { assetType in
            for key in keys {
                XCTAssertNotNil(assetsStorage.assetURLIfExist(for: key, assetType: assetType))
            }
        }
    }
}

private final class MockFileManager: FileManager {
    
    private(set) var filesMap: [String : Data] = [:]
    
    override func fileExists(atPath path: String) -> Bool {
        filesMap[path] != nil 
    }
    
    override func contents(atPath path: String) -> Data? {
        filesMap[path]
    }
    
    override func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey : Any]? = nil) -> Bool {
        filesMap[path] = data!
        return true
    }
    
    override func removeItem(atPath path: String) throws {
        filesMap[path] = nil
    }
    
    override func contentsOfDirectory(atPath path: String) throws -> [String] {
        []
    }
}
