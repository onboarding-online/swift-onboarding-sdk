//
//  File.swift
//
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation
import StoreKit

public struct OPSProductsResponse {
    public let products: [SKProduct]
    public let invalidProductIdentifiers: [String]
}

extension OPSProductsResponse {
    init(skProductResponse: SKProductsResponse) {
        self.products = skProductResponse.products
        self.invalidProductIdentifiers = skProductResponse.invalidProductIdentifiers
    }
}
