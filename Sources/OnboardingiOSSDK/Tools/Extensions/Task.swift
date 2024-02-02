//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 02.02.2024.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds duration: TimeInterval) async {
        let duration = UInt64(duration * 1_000_000_000)
        try? await Task.sleep(nanoseconds: duration)
    }
}
