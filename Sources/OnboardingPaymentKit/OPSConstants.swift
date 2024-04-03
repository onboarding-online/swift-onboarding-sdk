//
//  File.swift
//
//
//  Created by Oleg Kuplin on 28.12.2023.
//

import Foundation

public typealias OPSEmptyCallback = ()->()
public typealias OPSEmptyResult = Result<Void, Error>
public typealias OPSEmptyResultCallback = (OPSEmptyResult)->()

let WorkingQueue = DispatchQueue(label: "com.ops.working.queue", qos: .userInitiated)

public enum PaymentsEnvironment: String {
    case production, sandbox
}
