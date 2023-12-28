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
    
    private var activeRequests = ProcessesManager<OPSProductsRequest, OPSProductsRequestResult>()
    private var products: Set<SKProduct> = []
    
}

// MARK: - Open methods
extension OPSProductsManager {
    
    func fetchProductsWith(ids: SKProductIDs, completion: @escaping OPSProductsRequestCompletion) {
        if let cachedProducts = self.cachedProductsWith(ids: ids) {
            OPSLogger.logEvent("ProductsRequest.Will return products with ids \(ids) from cache")
            completion(.success(OPSProductsResponse(products: Array(cachedProducts), invalidProductIdentifiers: [])))
        } else if let activeRequest = self.activeRequests.processes.first(where: { $0.object.productIds == ids }) {
            OPSLogger.logEvent("ProductsRequest.Will add completion handlers for products with ids \(ids) to ongoing queue")
            activeRequest.addHandler(completion)
        } else  {
            OPSLogger.logEvent("ProductsRequest.Will start fetching products with ids \(ids)")
            let request = OPSProductsRequest(productIds: ids, completion: { [weak self] result in
                DispatchQueue.main.async { [weak self] in
                    self?.handleProductsRequestResult(result, forProductIds: ids)
                }
            })
            request.start()
            
            activeRequests.addProcess(.init(object: request, handlers: [completion]))
        }
    }
    
}

// MARK: - Private methods
private extension OPSProductsManager {
    
    func handleProductsRequestResult(_ result: OPSProductsRequestResult, forProductIds ids: SKProductIDs) {
        switch result {
        case .success(let response):
            self.products.formUnion(response.products)
        case .failure:
            Void()
        }
        activeRequests.completeWhere({ $0.productIds == ids }, withResult: result)
    }
    
    func cachedProductsWith(ids: SKProductIDs) -> Set<SKProduct>? {
        let cachedProducts = products.filter({ ids.contains($0.productIdentifier) })
        if cachedProducts.count == ids.count {
            return cachedProducts
        }
        
        return nil
    }
    
}
