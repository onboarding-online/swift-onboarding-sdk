//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 04.01.2024.
//

import Foundation

enum StoreKitSubscriptionPeriod: Hashable {
    case days(Int), week(Int), month(Int), year(Int)
    
    var analyticsName: String {
        switch self {
        case .days(let count):
            return "subscriptionDaily_\(count)"
        case .week(let count):
            return "subscriptionWeekly_\(count)"
        case .month(let count):
            return "subscriptionMonthly_\(count)"
        case .year(let count):
            return "subscriptionAnnual_\(count)"
        }
    }
    
    var numberOfUnits: Int {
        switch self {
        case .days(let int):
            return int
        case .week(let int):
            return int
        case .month(let int):
            return int
        case .year(let int):
            return int
        }
    }
    
    var periodLocalizedUnitName: String {
        let unit: NSCalendar.Unit
        switch self {
        case .days:
            unit = .day
        case .week:
            unit = .weekOfMonth
        case .month:
            unit = .month
        case .year:
            unit = .year
        }
        return Calendar.current.localizedUnitTitle(unit, value: numberOfUnits)
    }
    
    var periodUnitCountLocalizedUnitName: String {
        let unit: NSCalendar.Unit
        var unitCount: Int
        
        switch self {
        case .days(let count):
            unit = .day
            unitCount = count
        case .week(let count):
            unit = .weekOfMonth
            unitCount = count

        case .month(let count):
            unit = .month
            unitCount = count

        case .year(let count):
            unit = .year
            unitCount = count

        }
        let unitName = Calendar.current.localizedUnitTitle(unit, value: unitCount)
       
        if unitCount > 1 {
            return "\(unitCount) \(unitName)"
        }
        
        return unitName
    }
}
