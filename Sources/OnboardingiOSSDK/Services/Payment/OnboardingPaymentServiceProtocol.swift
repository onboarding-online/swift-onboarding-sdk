//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation
import StoreKit

public protocol OnboardingPaymentServiceProtocol {
    func fetchProductsWith(ids: Set<String>) async throws -> [SKProduct]
    func restorePurchases() async throws
}
