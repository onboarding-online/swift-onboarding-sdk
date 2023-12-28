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

final class OPSProductsRequest: NSObject {
        
    let productIds: Set<String>
    private let completion: OPSProductsRequestCompletion
    private let request: SKProductsRequest
    
    init(productIds: Set<String>, completion: @escaping OPSProductsRequestCompletion) {
        self.productIds = productIds
        self.completion = completion
        self.request = SKProductsRequest(productIdentifiers: productIds)
        super.init()
        request.delegate = self
        OPSLogger.logEvent("Did create new Products request with product ids \(productIds)")
    }
    
    func start() {
        OPSLogger.logEvent("Did start fetching products with ids \(productIds)")
        request.start()
    }
    
}

// MARK: - SKProductsRequestDelegate
extension OPSProductsRequest: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        OPSLogger.logEvent("Did receive products response with\nProducts: \(response.products.map({ $0.productIdentifier }))\nInvalid product identifiers: \(response.invalidProductIdentifiers)")
        completion(.success(OPSProductsResponse(skProductResponse: response)))
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        OPSLogger.logError(error)
        completion(.failure(error))
    }
}
