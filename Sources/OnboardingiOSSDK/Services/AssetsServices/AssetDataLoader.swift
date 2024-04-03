//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 20.01.2024.
//

import Foundation

protocol AssetDataLoader {
    func loadAssetDataFrom(url: URL) async throws -> Data
}

struct DefaultAssetDataLoader: AssetDataLoader {
    func loadAssetDataFrom(url: URL) async throws -> Data {
        let imageData = try Data(contentsOf: url)
        return imageData
    }
}
