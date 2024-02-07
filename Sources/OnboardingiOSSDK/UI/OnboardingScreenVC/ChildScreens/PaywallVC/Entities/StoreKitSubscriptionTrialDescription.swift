//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 04.01.2024.
//

import Foundation

struct StoreKitSubscriptionTrialDescription: Hashable {
    let period: StoreKitSubscriptionPeriod
    let periodDuration: Int
    let localizedPrice: String
}
