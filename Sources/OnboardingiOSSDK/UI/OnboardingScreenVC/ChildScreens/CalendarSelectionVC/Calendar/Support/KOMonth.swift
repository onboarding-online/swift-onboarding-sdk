//
//  KOMonth.swift
//  KOCalendar
//
//  Created by Oleg Home on 14/10/2018.
//  Copyright © 2018 Oleg Home. All rights reserved.
//

import Foundation

struct KOMonth {
    
    let firstWeekday: WeekDay
    fileprivate(set) var year: Int
    fileprivate(set) var monthNumber: Int
    fileprivate(set) var days: [KODay] = [KODay]()
    fileprivate(set) var isCurrentMonth = false
    
    var monthName = ""
    
    init(year: Int, monthNumber: Int, firstWeekday: WeekDay, calendar: Calendar) {
        self.year = year
        self.monthNumber = monthNumber
        self.firstWeekday = firstWeekday
        setupDays(calendar: calendar)
    }
    
    mutating func setupDays(calendar: Calendar) {
        
        var dateComponents = DateComponents(year: year, month: monthNumber)
        let currentDateComponents = calendar.dateComponents([.day, .month, .year], from: Date())
        if currentDateComponents.month == monthNumber,
            currentDateComponents.year == year {
            isCurrentMonth = true
        }
        
        if calendar.monthSymbols.count > monthNumber {
            monthName = calendar.monthSymbols[monthNumber - 1]
        }
        
        guard let date = calendar.date(from: dateComponents) else { return }
        guard let range = calendar.range(of: .day, in: .month, for: date) else { return }
        
        let numDays = range.count
        
        days.removeAll()
        for i in 1...numDays {
            dateComponents.day = i
            
            if let date = calendar.date(from: dateComponents) {
                if i == 1 {
                    checkIfFirstDay(date: date, calendar: calendar)
                }
                let isToday = isCurrentMonth && currentDateComponents.day == i
                let koDay = KODay(date: date, dayNumber: i, monthNumber: monthNumber, isToday: isToday, calendar: calendar)
                
                days.append(koDay)
            }
        }
    }
    
    mutating func checkIfFirstDay(date: Date, calendar: Calendar) {
        var date = date
        var weekDayComponent = calendar.dateComponents([.weekday], from: date).weekday!
        
        while weekDayComponent != firstWeekday.rawValue {
            let emptyDay = KODay(date: date, dayNumber: 0, isInCurrentMonth: false, calendar: calendar)
            days.append(emptyDay)
            
            date = calendar.date(byAdding: .day, value: -1, to: date)!
            weekDayComponent = calendar.dateComponents([.weekday], from: date).weekday!
        }
    }

}
