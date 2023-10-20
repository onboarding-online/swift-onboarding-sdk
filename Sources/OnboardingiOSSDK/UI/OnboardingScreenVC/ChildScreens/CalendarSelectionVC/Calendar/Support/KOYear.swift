//
//  KOYear.swift
//  KOCalendar
//
//  Created by Oleg Home on 14/10/2018.
//  Copyright © 2018 Oleg Home. All rights reserved.
//

import Foundation

struct KOYear {
    
    fileprivate(set) var yearNumber: Int
    fileprivate(set) var months: [KOMonth]
    
    init(yearNumber: Int, months: [KOMonth]) {
        self.yearNumber = yearNumber
        self.months = months
    }
    
}
