//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation

public protocol OnboardingPaymentServiceProtocol {
    func restorePurchases() async throws
}
