//
//  AssetsStorageService.swift
//  OnboardingOnline
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import Foundation

protocol AssetsStorageProtocol {
    func assetURLIfExist(for key: String, assetType: StoredAssetType) -> URL?
    func getStoredAssetData(for key: String, assetType: StoredAssetType) -> Data?
    func storeAssetData(_ data: Data, for key: String, assetType: StoredAssetType)
    func clearStoredAssets()
}

struct AssetsStorage {
    
    private let fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        checkStoredAssetsDirectory()
    }
}

// MARK: - Open methods
extension AssetsStorage: AssetsStorageProtocol {
    func assetURLIfExist(for key: String, assetType: StoredAssetType) -> URL? {
        let path = assetType.pathForStoredAssetAtKey(key)
        if !fileManager.fileExists(atPath: path) {
            return nil
        }
        return URL(fileURLWithPath: path)
    }
    
    func getStoredAssetData(for key: String, assetType: StoredAssetType) -> Data? {
        let path = assetType.pathForStoredAssetAtKey(key)
        return fileManager.contents(atPath: path)
    }
    
    func storeAssetData(_ data: Data, for key: String, assetType: StoredAssetType) {
        let path = assetType.pathForStoredAssetAtKey(key)
        fileManager.createFile(atPath: path, contents: data)
    }
    
    func clearStoredAssets() {
        StoredAssetType.allCases.forEach { type in
            clearStoredAssetsAt(storagePath: type.storagePath)
        }
    }
}

// MARK: - Private methods
private extension AssetsStorage {
    func checkStoredAssetsDirectory() {
        StoredAssetType.allCases.forEach { type in
            checkStoredDirectory(path: type.storagePath as String)
        }
    }
    
    func checkStoredDirectory(path: String) {
        if !fileManager.fileExists(atPath: path) {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                OnboardingLogger.logError("Couldn't create directory for assets at \(path)")
            }
        }
    }
    
    func clearStoredAssetsAt(storagePath: NSString) {
        do {
            let paths = try fileManager.contentsOfDirectory(atPath: storagePath as String)
            try paths.forEach { path in
                try fileManager.removeItem(atPath: storagePath.appendingPathComponent(path))
            }
        } catch { }
    }
}

enum StoredAssetType: CaseIterable {
    case image
    case video
    case videoThumbnail
    
    var storagePath: NSString {
        switch self {
        case .image:
            return (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("StoredImages") as NSString
        case .video:
            return (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("StoredVideos") as NSString
        case .videoThumbnail:
            return (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("StoredVideoThumbnails") as NSString
        }
    }
    
    var pathExtension: String {
        switch self {
        case .image, .videoThumbnail:
            return "jpeg"
        case .video:
            return "mp4"
        }
    }
    
    func pathForStoredAssetAtKey(_ key: String) -> String {
        let encodedKey = Data(key.utf8).base64EncodedString().replacingOccurrences(of: "/", with: "").prefix(250)
        return pathForStoredAssetWithName(String(encodedKey))
    }
    
    func pathForStoredAssetWithName(_ name: String) -> String {
        (storagePath.appendingPathComponent(name) as NSString).appendingPathExtension(pathExtension)!
    }
}
