//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 20.01.2024.
//

import UIKit

protocol ImagesCacheStorageProtocol {
    func getCachedImage(for key: String) -> UIImage?
    func cache(image: UIImage, forKey key: String)
    func clearCache()
}

final class ImagesCacheStorage {
    
    private var imageCache = [CacheKeyDescription: UIImage]()
    private let maxCacheSize: Int
    private let serialQueue = DispatchQueue(label: "com.onboarding.online.image.cache.serial")
    
    init(maxCacheSize: Int = 1_250_000_000) { // 1250 MB
        self.maxCacheSize = maxCacheSize
    }
}

// MARK: - Open methods
extension ImagesCacheStorage: ImagesCacheStorageProtocol {
    var cacheMemoryUsage: Int {
        imageCache.values.map({ $0.memoryUsage }).reduce(0, { $0 + $1 })
    }
    var numberOfCachedItems: Int { imageCache.count }
    
    func getCachedImage(for key: String) -> UIImage? {
        serialQueue.sync {
            let key = CacheKeyDescription(key)
            if let image = self.imageCache[key] {
                /// Update last used date
                self.imageCache[key] = nil
                self.imageCache[key] = image
                return image
            }
            return nil
        }
    }
    
    func cache(image: UIImage, forKey key: String) {
        serialQueue.sync {
            var currentCacheUsage = cacheMemoryUsage
            let newImageMemoryUsage = image.memoryUsage
            if (currentCacheUsage + newImageMemoryUsage) > maxCacheSize {
                let sortedKeys = imageCache.keys.sorted(by: { $0.lastUsedDate < $1.lastUsedDate })
                for key in sortedKeys {
                    let image = self.imageCache[key]!
                    let imageMemoryUsage = image.memoryUsage
                    imageCache.removeValue(forKey: key)
                    currentCacheUsage -= imageMemoryUsage
                    if (currentCacheUsage + newImageMemoryUsage) <= maxCacheSize {
                        break
                    }
                }
            }
            
            self.imageCache[.init(key)] = image
        }
    }
    
    func clearCache() {
        serialQueue.sync {
            imageCache.removeAll()
        }
    }
}

// MARK: - Private methods
private extension ImagesCacheStorage {
    struct CacheKeyDescription: Hashable {
        let key: String
        let lastUsedDate = Date()
        
        init(_ key: String) {
            self.key = key
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.key == rhs.key
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(key)
        }
    }
}

extension UIImage {
    static let bitPerPixel: Int = 4
    var memoryUsage: Int { Int(size.width) * Int(size.height) * Int(scale) * UIImage.bitPerPixel * (images?.count ?? 1) }
}

