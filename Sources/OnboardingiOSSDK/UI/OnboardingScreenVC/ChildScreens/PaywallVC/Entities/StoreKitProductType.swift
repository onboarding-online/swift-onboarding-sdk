//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 04.01.2024.
//

import Foundation

enum StoreKitProductType: Hashable {
    case oneTimePurchase
    case subscription(description: StoreKitSubscriptionDescription)
}
