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
}
