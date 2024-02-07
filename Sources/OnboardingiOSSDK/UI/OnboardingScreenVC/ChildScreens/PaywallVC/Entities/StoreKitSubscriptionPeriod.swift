//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 04.01.2024.
//

import Foundation

enum StoreKitSubscriptionPeriod: Hashable {
    case days(count: Int), week, month, year
    
    var analyticsName: String {
        switch self {
        case .days(let count):
            return "subscriptionDaily_\(count)"
        case .week:
            return "subscriptionWeekly"
        case .month:
            return "subscriptionMonthly"
        case .year:
            return "subscriptionAnnual"
        }
    }
}
