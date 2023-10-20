//
//  File.swift
//  
//
//  Copyright 2023 Onboarding.online on 18.03.2023.
//

import Foundation
extension NSObject {
    
    var className: String {
        return String(describing: type(of: self)).components(separatedBy: ".").last ?? ""
    }
    
    class var className: String {
        return String(describing: self).components(separatedBy: ".").last ?? ""
    }
    
}
