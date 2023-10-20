//
//  AssetsStorageService.swift
//  OnboardingOnline
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import Foundation

public struct AssetsStorage {
    
    private let fileManager = FileManager.default
    
    init() {
        checkStoredAssetsDirectory()
    }
}

// MARK: - Open methods
extension AssetsStorage {
    
    func assetURLIfExist(for key: String, assetType: StoredAssetType) -> URL? {
        let path = pathForStoredAssetAtKey(key, assetType: assetType)
        if !fileManager.fileExists(atPath: path) {
            return nil
        }
        return URL(fileURLWithPath: path)
    }
    
    func assetURL(for key: String, assetType: StoredAssetType) -> URL {
        let path = pathForStoredAssetAtKey(key, assetType: assetType)
        return URL(fileURLWithPath: path)
    }
    
    func getStoredAssetData(for key: String, assetType: StoredAssetType) -> Data? {
        let url = assetURL(for: key, assetType: assetType)
        return try? Data.init(contentsOf: url)
    }
    
    func storeAssetData(_ data: Data, for key: String, assetType: StoredAssetType) {
        do {
            let url = assetURL(for: key, assetType: assetType)
            try data.write(to: url)
        } catch {
            print("Error: Couldn't save cached image to files")
        }
    }
    
    func clearStoredAssets() {
        StoredAssetType.allCases.forEach { type in
            clearStoredAssetsAt(storagePath: type.storagePath)
        }
    }
}

// MARK: - Private methods
private extension AssetsStorage {
    
    func pathForStoredAssetAtKey(_ key: String, assetType: StoredAssetType) -> String {
        let encodedKey = Data(key.utf8).base64EncodedString().replacingOccurrences(of: "/", with: "").prefix(250)
        return pathForStoredAssetWithName(String(encodedKey), assetType: assetType)
    }
    
    
    func pathForStoredAssetWithName(_ name: String, assetType: StoredAssetType) -> String {
        (assetType.storagePath.appendingPathComponent(name) as NSString).appendingPathExtension(assetType.pathExtension)!
    }
    
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
                print("Error: Couldn't create directory for assets at \(path)")
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
    }
