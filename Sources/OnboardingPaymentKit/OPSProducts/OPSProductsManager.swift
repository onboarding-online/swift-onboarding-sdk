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
    
    private var products: Set<SKProduct> = []
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
        self.products.formUnion(response.products)
        OPSLogger.logEvent("ProductsRequest.Did fetch products with ids \(ids)")
        return response
    }
}

// MARK: - Private methods
private extension OPSProductsManager {
    func cachedProductsWith(ids: SKProductIDs) -> Set<SKProduct>? {
        let cachedProducts = products.filter({ ids.contains($0.productIdentifier) })
        if cachedProducts.count == ids.count {
            return cachedProducts
        }
        
        return nil
    }
}
