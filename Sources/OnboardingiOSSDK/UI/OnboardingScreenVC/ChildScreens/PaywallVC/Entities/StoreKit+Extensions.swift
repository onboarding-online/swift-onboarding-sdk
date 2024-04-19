//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 04.01.2024.
//

import Foundation
import StoreKit

extension SKProduct {
    fileprivate static var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }
    
    var currencyCode: String? {
        if #available(iOS 16, *) {
            guard let currency = priceLocale.currency?.identifier else { return nil }
            return currency
        } else {
            guard let currency = priceLocale.currencyCode else { return nil }
            return currency
        }
    }
    
    var localizedPrice: String? {
        SKProduct.localizedPriceFor(price: self.price, locale: self.priceLocale)
    }
    
    var introductionLocalizedPrice: String? {
        guard let introductoryPeriod = self.introductoryPrice else { return nil }
        
        return SKProduct.localizedPriceFor(price: introductoryPeriod.price, locale: introductoryPeriod.priceLocale)
    }
    
    func localizedPriceFor(_ value: Double) -> String? {
        SKProduct.localizedPriceFor(price: value as NSNumber, locale: self.priceLocale)
    }
    
    func localizedPriceFor(_ value: Double, currencyFormat: NumberFormatter.Style) -> String? {
        SKProduct.localizedPriceFor(price: value as NSNumber, locale: self.priceLocale, currencyFormat: currencyFormat)
    }
    
    fileprivate static func localizedPriceFor(price: NSNumber, locale: Locale) -> String? {
        let formatter = SKProduct.formatter
        formatter.locale = locale
        formatter.roundingMode = .down
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: price)
    }
    
    func localizedPriceFor(currencyFormat: NumberFormatter.Style) -> String? {
        SKProduct.localizedPriceFor(price: self.price as NSNumber, locale: self.priceLocale, currencyFormat: currencyFormat)
    }
    
    fileprivate static func localizedPriceFor(price: NSNumber, locale: Locale, currencyFormat: NumberFormatter.Style) -> String? {
        let formatter = SKProduct.formatter
        formatter.numberStyle = currencyFormat
        formatter.locale = locale
        formatter.roundingMode = .down
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: price)
    }
    
    var isWithTrial: Bool { introductoryPrice != nil }
    
}

extension SKProductDiscount {
    var localizedPrice: String? {
        let locale: Locale
        if #available(iOS 14.0, *) {
            locale = self.priceLocale
        } else {
            locale = .current
        }
        return SKProduct.localizedPriceFor(price: self.price, locale: locale)
    }
}

extension SKProductSubscriptionPeriod {
    
    var period: StoreKitSubscriptionPeriod {
        if unit == .day && self.numberOfUnits == 7 {
            return .week(1)
        }
        
        switch unit {
        case .week:
            return .week(numberOfUnits)
        case .month:
            return .month(numberOfUnits)
        case .year:
            return .year(numberOfUnits)
        case .day:
            return .days(numberOfUnits)
        @unknown default:
            return .year(numberOfUnits)
        }
    }
    
}

extension SKProduct {
    static func mock(productIds: Set<String>) -> [SKProduct] {
        var products = [SKProduct]()
        let locale = Locale.current
        for id in productIds {
            let product = SKProduct()
            let price = Double(arc4random_uniform(100)) + 3.99
            product.setValue(id, forKey: "productIdentifier")
            product.setValue(price, forKey: "price")
            product.setValue(locale, forKey: "priceLocale")
            
            let period = SKProductSubscriptionPeriod()
            period.setValue(SKProduct.PeriodUnit.day.rawValue, forKey: "unit")
            period.setValue(1, forKey: "numberOfUnits")
            
            product.setValue(period, forKey: "subscriptionPeriod")
            
            products.append(product)
        }
        return products
    }
}
