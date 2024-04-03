//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 29.12.2023.
//

import XCTest
import StoreKit
@testable import OnboardingPaymentKit

final class OPSProductsManagerTests: XCTestCase {
    
    private var mockFetcher: MockSKProductsFetcher!
    private var productsManager: OPSProductsManager!
    
    override func setUp() async throws {
        mockFetcher = MockSKProductsFetcher()
        productsManager = OPSProductsManager(fetcher: mockFetcher)
    }
    
    func testProductsLoadedAndCached() async throws {
        let productIds: SKProductIDs = ["1", "2"]
        let products = try await productsManager.fetchProductsWith(ids: productIds)
        XCTAssertEqual(productIds, Set(products.products.map({ $0.productIdentifier })))
        XCTAssertEqual([productIds], mockFetcher.fetchRequests)
        
        let products2 = try await productsManager.fetchProductsWith(ids: productIds)
        XCTAssertEqual(productIds, Set(products2.products.map({ $0.productIdentifier })))
        XCTAssertEqual([productIds], mockFetcher.fetchRequests)
    }
 
    func testDifferentProductsLoadedAndCached() async throws {
        let productIds: SKProductIDs = ["1", "2"]
        let _ = try await productsManager.fetchProductsWith(ids: productIds)
        
        let productIds2: SKProductIDs = ["2", "3"]
        let _ = try await productsManager.fetchProductsWith(ids: productIds2)
        
        let productIds3: SKProductIDs = ["1", "2", "3"]
        let _ = try await productsManager.fetchProductsWith(ids: productIds3)
        
        XCTAssertEqual([productIds, productIds2], mockFetcher.fetchRequests)
    }
}

private final class MockSKProductsFetcher: SKProductsFetcher {
    
    private(set) var fetchRequests = [Set<String>]()
    
    func fetch(productIds: Set<String>) async throws -> OnboardingPaymentKit.OPSProductsResponse {
        fetchRequests.append(productIds)
        let products = productIds.map { id in
            let product = SKProduct()
            product.setValue(id, forKey: "productIdentifier")
            
            return product
        }
        
        return .init(products: products, invalidProductIdentifiers: [])
    }
}
