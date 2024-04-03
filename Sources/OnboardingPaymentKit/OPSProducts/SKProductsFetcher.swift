//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 29.12.2023.
//

import Foundation

protocol SKProductsFetcher {    
    func fetch(productIds: Set<String>) async throws -> OPSProductsResponse
}
