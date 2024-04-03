//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 29.12.2023.
//

import Foundation

public enum OPSTransactionStatus: Sendable {
    case purchased(completeTransaction: @Sendable ()->()), deffered
}
