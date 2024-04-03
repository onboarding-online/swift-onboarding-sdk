//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 04.01.2024.
//

import Foundation
import StoreKit

struct StoreKitProductDiscount: Hashable {
    let price: Double
    let localizedPrice: String
    let identifier: String?
    let paymentMode: SKProductDiscount.PaymentMode
    
    let period: StoreKitSubscriptionPeriod

    
    init?(skProductDiscount: SKProductDiscount) {
        guard let localizedPrice = skProductDiscount.localizedPrice else {
            OnboardingLogger.logError("Failed to get localized price for SKProductDiscount: \(skProductDiscount.identifier ?? "-")")
            return nil }
        
        self.price = skProductDiscount.price.doubleValue
        self.localizedPrice = localizedPrice
        self.identifier = skProductDiscount.identifier
        self.paymentMode = skProductDiscount.paymentMode
        self.period =  skProductDiscount.subscriptionPeriod.period
    }
}
