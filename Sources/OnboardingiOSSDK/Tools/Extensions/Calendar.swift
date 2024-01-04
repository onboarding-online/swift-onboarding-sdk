//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 04.01.2024.
//

import Foundation

extension Calendar {
    func localizedUnitTitle(_ unit: NSCalendar.Unit,
                            value: Int = 1) -> String {
        let emptyString = String()
        let date = Date()
        let component = getComponent(from: unit)
        guard let sinceUnits = self.date(byAdding: component, value: value, to: date) else {
            return emptyString
        }
        
        let formatter = DateComponentsFormatter()
        formatter.calendar = self
        formatter.allowedUnits = [unit]
        formatter.unitsStyle = .full
        guard let string = formatter.string(from: date, to: sinceUnits) else {
            return emptyString
        }
        
        return string
            .replacingOccurrences(of: String(value),
                                  with: emptyString)
            .trimmingCharacters(in: .whitespaces)
            .capitalized
    }
    
    private func getComponent(from unit: NSCalendar.Unit) -> Component {
        let component: Component
        
        switch unit {
        case .era:
            component = .era
        case .year:
            component = .year
        case .month:
            component = .month
        case .day:
            component = .day
        case .hour:
            component = .hour
        case .minute:
            component = .minute
        case .second:
            component = .second
        case .weekday:
            component = .weekday
        case .weekdayOrdinal:
            component = .weekdayOrdinal
        case .quarter:
            component = .quarter
        case .weekOfMonth:
            component = .weekOfMonth
        case .weekOfYear:
            component = .weekOfYear
        case .yearForWeekOfYear:
            component = .yearForWeekOfYear
        case .nanosecond:
            component = .nanosecond
        case .calendar:
            component = .calendar
        case .timeZone:
            component = .timeZone
        default:
            component = .calendar
        }
        return component
    }
}
