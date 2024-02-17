//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 04.01.2024.
//

import Foundation

struct StoreKitSubscriptionDescription: Hashable {
    let localizedPrice: String
    let period: StoreKitSubscriptionPeriod
    let trialDescription: StoreKitSubscriptionTrialDescription?
    
    var periodLocalizedUnitName: String {
        let unit: NSCalendar.Unit
        var unitCount: Int
        
        switch period {
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
        return Calendar.current.localizedUnitTitle(unit, value: unitCount)
    }
    
    var periodUnitCountLocalizedUnitName: String {
        let unit: NSCalendar.Unit
        var unitCount: Int
        
        switch period {
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
