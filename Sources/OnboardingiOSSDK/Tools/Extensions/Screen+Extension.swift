//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 06.04.2024.
//

import Foundation
import ScreensGraph

extension Screen {
    var useLocalAssetsIfAvailable: Bool { _struct.useLocalAssetsIfAvailable }
    
    func listValuesFor(indexes: [Int]) -> String {
       return _struct.listValuesFor(indexes: indexes)
    }

}
