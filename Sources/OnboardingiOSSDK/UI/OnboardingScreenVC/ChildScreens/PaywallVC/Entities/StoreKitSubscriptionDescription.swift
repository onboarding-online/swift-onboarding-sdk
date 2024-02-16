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
        switch period {
        case .days:
            unit = .day
        case .week:
            unit = .weekOfMonth
        case .month:
            unit = .month
        case .year:
            unit = .year
        }
        return Calendar.current.localizedUnitTitle(unit, value: 3)
    }
}
