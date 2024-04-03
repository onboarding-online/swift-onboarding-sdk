//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation

public struct AppStoreValidatedReceipt: Codable, Hashable {
    
    public let status: Int
    public let environment: String
    public let receipt: AppStoreReceipt
    public let latestReceipt: Data?
    public let pendingRenewalInfo: [AppStorePendingRenewalInfo]?
    public let latestReceiptInfo: [AppStoreReceiptInApp]?
    
    public func isProductPurchased(productId: String) -> Bool {
        if let info = latestReceiptInfo {
            return info.first(where: { $0.productId == productId }) != nil
        }
        return false
    }
    
    public func nonSubscriptionReceipts() -> [AppStoreReceiptInApp] {
        guard let latestReceiptInfo = self.latestReceiptInfo else { return [] }
        
        return latestReceiptInfo.filter({ !$0.isSubscription })
    }
    
    public func lastPurchaseReceipts() -> AppStoreReceiptInApp? {
        let receipts = nonSubscriptionReceipts()
        return receipts.first
    }
    
    public func activeSubscriptionReceipt() -> AppStoreReceiptInApp? {
        latestReceiptInfo?.first(where: { $0.expiresDate != nil && $0.expiresDate! > Date() })
    }
    
    public func subscriptionsStatuses() -> [SubscriptionStatus] {
        guard let latestReceiptInfo = self.latestReceiptInfo else { return [] }
        
        var statuses = [SubscriptionStatus]()
        let productsToIds = [String : [AppStoreReceiptInApp]].init(grouping: latestReceiptInfo, by: { $0.productId })
        
        for (productId, receipts) in productsToIds {
            let subscriptionReceipts = receipts.filter({ $0.isSubscription })
            let sortedReceipts = subscriptionReceipts.sorted(by: { $0.expiresDate! > $1.expiresDate! })
            
            if let latestReceipt = sortedReceipts.first,
               let expirationDate = latestReceipt.expiresDate {
                let info = SubscriptionStatusInfo(expirationDate: expirationDate, productId: productId, appStoreReceipt: latestReceipt)
                if expirationDate > Date() {
                    statuses.append(.active(info: info))
                } else {
                    statuses.append(.expired(info: info))
                }
            }
        }
        
        return statuses
    }
}

public struct AppStoreReceipt: Codable, Hashable {
    public let receiptType: String
    public let appItemId: Int
    public let receiptCreationDateMs: String
    public var receiptCreationDate: Date { Date(millisecondsSince1970: TimeInterval(receiptCreationDateMs) ?? 0) }
    public let inApp: [AppStoreReceiptInApp]?
}

public struct AppStoreReceiptInApp: Codable, Hashable {
    public let productId: String
    public let quantity: String
    public let transactionId: String
    public let originalTransactionId: String
    public let purchaseDateMs: String
    public var purchaseDate: Date { Date(millisecondsSince1970: TimeInterval(purchaseDateMs) ?? 0) }
    public let originalPurchaseDateMs: String?
    public var originalPurchaseDate: Date? {
        if let date = originalPurchaseDateMs {
            return Date(millisecondsSince1970: TimeInterval(date) ?? 0)
        }
        return nil
    }
    public let isTrialPeriod: String
    public let expiresDateMs: String?
    public var expiresDate: Date? {
        if let date = expiresDateMs {
            return Date(millisecondsSince1970: TimeInterval(date) ?? 0)
        }
        return nil
    }
    public let isInIntroOfferPeriod: String?
    public let webOrderLineItemId: String?
    public let isUpgraded: String? // An indicator that a subscription has been canceled due to an upgrade. This field is only present for upgrade transactions. Value: true
    public let cancellationReason: AppStoreCancellationReason?
    public let cancellationDateMs: String?
    public var cancellationDate: Date? {
        if let date = cancellationDateMs {
            return Date(millisecondsSince1970: TimeInterval(date) ?? 0)
        }
        return nil
    }
    public var isSubscription: Bool { expiresDateMs != nil && cancellationDateMs == nil }
}

public struct AppStorePendingRenewalInfo: Codable, Hashable {
    public let productId: String
    public let autoRenewProductId: String
    public let originalTransactionId: String
    public let autoRenewStatus: AppStorePendingRenewalInfoStatus
}

public enum AppStorePendingRenewalInfoStatus: String, Codable, Hashable {
    case renewOn = "1"
    case renewOff = "0"
}

public enum AppStoreCancellationReason: String, Codable, Hashable {
    case issueInApp = "1"
    case otherReason = "0"
}

public enum SubscriptionStatus {
    case active(info: SubscriptionStatusInfo)
    case expired(info: SubscriptionStatusInfo)
    
    public var isActive: Bool {
        switch self {
        case .active:
            return true
        case .expired:
            return false
        }
    }
}

public struct SubscriptionStatusInfo {
    public let expirationDate: Date
    public let productId: String
    public let appStoreReceipt: AppStoreReceiptInApp
}

extension Date {
    
    init(millisecondsSince1970: TimeInterval) {
        self = Date(timeIntervalSince1970: millisecondsSince1970 / 1000)
    }
    
}
