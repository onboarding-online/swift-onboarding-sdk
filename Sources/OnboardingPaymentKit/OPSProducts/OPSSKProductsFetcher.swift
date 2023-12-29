//
//  File.swift
//
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation
import Combine
import StoreKit

public typealias OPSProductsRequestResult = Result<OPSProductsResponse, Error>
public typealias OPSProductsRequestCompletion = (OPSProductsRequestResult)->()

protocol SKProductsFetcher: Equatable {
    var productIds: Set<String> { get }
    
    func fetch(productIds: Set<String>) async throws -> OPSProductsResponse
}

final class OPSSKProductsFetcher: NSObject {
        
    private(set) var productIds: Set<String> = []
    private var completion: OPSProductsRequestCompletion?
    
}

// MARK: - SKProductsFetcher
extension OPSSKProductsFetcher: SKProductsFetcher {
    @available(*, renamed: "fetch(productIds:)")
    func fetch(productIds: Set<String>,
               completion: @escaping OPSProductsRequestCompletion) {
        OPSLogger.logEvent("Did start fetching products with ids \(productIds)")
        self.productIds = productIds
        self.completion = completion

        let request = SKProductsRequest(productIdentifiers: productIds)
        request.delegate = self
        request.start()
    }
    
    func fetch(productIds: Set<String>) async throws -> OPSProductsResponse {
        try await withCheckedThrowingContinuation { continuation in
            fetch(productIds: productIds) { result in
                continuation.resume(with: result)
            }
        }
    }
}

// MARK: - SKProductsRequestDelegate
extension OPSSKProductsFetcher: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        OPSLogger.logEvent("Did receive products response with\nProducts: \(response.products.map({ $0.productIdentifier }))\nInvalid product identifiers: \(response.invalidProductIdentifiers)")
        completion?(.success(OPSProductsResponse(skProductResponse: response)))
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        OPSLogger.logError(error)
        completion?(.failure(error))
    }
}
