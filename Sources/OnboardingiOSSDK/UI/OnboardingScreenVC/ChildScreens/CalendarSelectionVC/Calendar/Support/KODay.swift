//
//  KODay.swift
//  KOCalendar
//
//  Created by Oleg Home on 14/10/2018.
//  Copyright © 2018 Oleg Home. All rights reserved.
//

import Foundation

struct KODay {
    fileprivate(set) var date: Date
    fileprivate(set) var dayNumber: Int
    fileprivate(set) var monthNumber: Int
    fileprivate(set) var isInCurrentMonth = true
    fileprivate(set) var isToday = false

    init(date: Date,
         dayNumber: Int,
         monthNumber: Int? = nil,
         isToday: Bool = false,
         isInCurrentMonth: Bool = true,
         calendar: Calendar) {
        self.date = date
        self.isToday = isToday
        self.isInCurrentMonth = isInCurrentMonth
        self.dayNumber = dayNumber
        if let monthNumber = monthNumber {
            self.monthNumber = monthNumber
        } else {
            self.monthNumber = calendar.dateComponents([.month], from: date).month ?? 1
        }
    }
    
}
