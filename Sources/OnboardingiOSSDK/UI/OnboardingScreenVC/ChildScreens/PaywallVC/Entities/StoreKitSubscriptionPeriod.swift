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
    
    var periodLocalizedUnitName: String {
        let unit: NSCalendar.Unit
        let count: Int = 1
        switch self {
        case .days(let count):
            unit = .day
        case .week:
            unit = .weekOfMonth
        case .month:
            unit = .month
        case .year:
            unit = .year
        }
        return Calendar.current.localizedUnitTitle(unit, value: count)
    }
}
