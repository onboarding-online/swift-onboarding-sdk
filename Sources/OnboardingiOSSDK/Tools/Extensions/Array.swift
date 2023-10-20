//
//  File.swift
//  
//
//  Copyright 2023 Onboarding.online on 18.03.2023.
//

import Foundation
import EventKit

extension Array where Element: Equatable {
    
    mutating func removeObject(object: Element)  {
        if let index = firstIndex(of: object) {
            remove(at: index)
        }
    }
    
    func satisfy(array: [Element]) -> Bool {
        return self.allSatisfy(array.contains)
    }
}

extension Array where Element: Hashable {
    
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
    
    func differenceOneMoreOptions(from other: [Element]) -> [Element] {
       
        let arrayC = self.filter{
            let dict = $0
            return !other.contains{ dict == $0 }
        }
        
        return arrayC
    }
    
    func equalElementsWith(array: [Element]) -> Bool {
        let selfUniqueValue = self.uniqued()
        let arrayUniqueValue = array.uniqued()

        if selfUniqueValue.count != arrayUniqueValue.count {
            return false
        }
        
        for element in selfUniqueValue {
            if arrayUniqueValue.firstIndex(of: element) == nil {
                return false
            }
        }
        return true
    }
    
    func uniqued() -> Array {
        var buffer = Array()
        var added = Set<Element>()
        for elem in self {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
    
}

public extension Sequence where Element : Hashable {
    
    func contains(_ elements: [Element]) -> Bool {
        return Set(elements).isSubset(of:Set(self))
    }
    
}

extension EKWeekday {
    
    static let allCases: [EKWeekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    
    var visibleName: String {
        elementInArray(Calendar.current.weekdaySymbols) ?? ""
    }
    
    var visibleShortName: String {
        elementInArray(Calendar.current.shortWeekdaySymbols) ?? ""
    }
    
}

private extension EKWeekday {

    func elementInArray<T>(_ array: [T]) -> T? {
        guard array.count == 7 else { return nil }
        /// First item in array always stands for Sunday. Tested on different locale/language settings.

        switch self {
        case .monday: return array[1]
        case .tuesday: return array[2]
        case .wednesday: return array[3]
        case .thursday: return array[4]
        case .friday: return array[5]
        case .saturday: return array[6]
        case .sunday: return array[0]
        }
    }
    
}
