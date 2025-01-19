//
//  Double.swift
//  OnboardingOnline
//
//
//  Copyright 2023 Onboarding.online on 09.03.2023.
//

import Foundation
import CoreGraphics

extension Bool {
    
    var intValue: Int {
        return self ? 1 : 0
    }
    
}

extension Double {
    
    func roundToDecimal(_ fractionDigits: Int) -> Double {
        let multiplier = pow(10, fractionDigits.doubleValue)
        return Darwin.round(self * multiplier) / multiplier
    }
    

    var rounededTowardZeroInt: Int? {
        if let intValue = Int.init(exactly: self.rounded(.towardZero)) {
            return intValue
        } else {
            return nil
        }
    }
        
}

extension Float {
    
    var rounededTowardZeroInt: Int? {
        if let intValue = Int.init(exactly: self.rounded(.towardZero)) {
            return intValue
        } else {
            return nil
        }
    }
        
}

extension Int {
    
    var megabytesToBytes: Int {
        return self * 1000_000
    }
    
}

extension Int: PickerItem {
    
    var title: String { stringValue }
    
    var int16Value: Int16 {
        return Int16(self)
    }
    
}

extension Int16 {
    
    var intValue: Int {
        return Int(self)
    }
    
}

extension Double? {
    
    var cgFloatValue: CGFloat {
        if let double = self {
            return CGFloat(double)
        } else {
            return CGFloat(0.0)
        }
    }
    
}

extension BinaryFloatingPoint {
    
    var cgFloatValue: CGFloat {
        return CGFloat(self)
    }
    
    var floatValue: Float {
        return Float(self)
    }
    
    var doubleValue: Double {
        return Double(self)
    }
    
    var intValue: Int {
        return Int(self)
    }
    
}

extension SignedInteger {
    
    var cgFloatValue: CGFloat {
        return CGFloat(self)
    }
    
    var floatValue: Float {
        return Float(self)
    }
    
    var doubleValue: Double {
        return Double(self)
    }
    
    var stringValue: String {
        return "\(self)"
    }
    
}

extension UInt32 {
    
    var cgFloatValue: CGFloat {
        return CGFloat(self)
    }
    
    var floatValue: Float {
        return Float(self)
    }
    
    var doubleValue: Double {
        return Double(self)
    }
    
}

extension Swift.Optional where Wrapped == String {
    
    var intValue: Int {
        return Int(self ?? "") ?? 0
    }
    
}

extension NSNumber {
    
    func stringWithMaximumFractionalDigits(_ fractionalDigitsCount: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = fractionalDigitsCount

        return numberFormatter.string(from: self) ?? ""
    }
    
}

