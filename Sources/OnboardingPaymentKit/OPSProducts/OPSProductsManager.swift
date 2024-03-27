//
//  File.swift
//
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation
import StoreKit

public typealias SKProductID = String
public typealias SKProductIDs = Set<String>

final class OPSProductsManager {
    
    private var products: [String : SKProduct] = [:]
    private let fetcher: any SKProductsFetcher
    
    init(fetcher: any SKProductsFetcher) {
        self.fetcher = fetcher
    }
}

// MARK: - Open methods
extension OPSProductsManager {
    func fetchProductsWith(ids: SKProductIDs) async throws -> OPSProductsResponse {
        if let cachedProducts = self.cachedProductsWith(ids: ids) {
            OPSLogger.logEvent("ProductsRequest.Will return products with ids \(ids) from cache")
            return OPSProductsResponse(products: Array(cachedProducts), invalidProductIdentifiers: [])
        }
        
        OPSLogger.logEvent("ProductsRequest.Will start fetching products with ids \(ids)")
        let response = try await fetcher.fetch(productIds: ids)
        cacheProducts(response.products)
        OPSLogger.logEvent("ProductsRequest.Did fetch products with ids \(ids)")
        
        return response
    }
    
    func cachedProducts(ids: SKProductIDs) -> OPSProductsResponse? {
        if let cachedProducts = self.cachedProductsWith(ids: ids) {
            OPSLogger.logEvent("ProductsRequest.Will return products with ids \(ids) from cache")
            return OPSProductsResponse(products: Array(cachedProducts), invalidProductIdentifiers: [])
        }
            
        return nil
    }
}

// MARK: - Private methods
private extension OPSProductsManager {
    func cacheProducts(_ products: [SKProduct]) {
        WorkingQueue.sync {
            for product in products {
                self.products[product.productIdentifier] = product
            }
        }
    }
    
    func cachedProductsWith(ids: SKProductIDs) -> Set<SKProduct>? {
        WorkingQueue.sync {
            var cachedProducts = Set<SKProduct>()
            for id in ids {
                if let product = self.products[id] {
                    cachedProducts.insert(product)
                }
            }
            
            if cachedProducts.count == ids.count {
                return cachedProducts
            }
            
            return nil
        }
    }
}
