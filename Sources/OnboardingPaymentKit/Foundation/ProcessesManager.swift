//
//  ProcessesManager.swift
//  SwiftPaymentsKit
//
//  Created by Oleg Home on 7/22/20.
//  Copyright © 2020 Oleg Home. All rights reserved.
//

import Foundation

final class ProcessesManager<Object: Equatable, CallbackResult> {
    
    typealias Process = ProcessCallbacksHolder<Object, CallbackResult>
    
    private(set) var processes = [Process]()
    
    func addProcess(_ process: Process) {
        processes.append(process)
    }
    
    func completeWhere(_ predicate: (Object) -> (Bool), withResult result: CallbackResult) {
        if let process = self.processes.first(where: { predicate($0.object) }) {
            completeProcess(process, withResult: result)
        }
    }
    
    func completeProcessOfObject(_ object: Object, withResult result: CallbackResult) {
        if let process = self.processes.first(where: { $0.object == object }) {
            completeProcess(process, withResult: result)
        }
    }
    
    func completeProcess(_ process: Process, withResult result: CallbackResult) {
        guard let requestIndex = self.processes.firstIndex(where: { $0 == process }) else { return }
        
        process.notifyWaiters(result: result)
        processes.remove(at: requestIndex)
    }
    
    func processWhere(_ predicate: (Object) -> (Bool)) -> Process? {
        return self.processes.first(where: { predicate($0.object) })
    }
    
    func objectWhere(_ predicate: (Object) -> (Bool)) -> Object? {
        return self.processes.first(where: { predicate($0.object) })?.object
    }
    
    func removeProcess(_ process: Process) {
        if let i = self.processes.firstIndex(where: { $0 == process }) {
            self.processes.remove(at: i)
        }
    }
    
}

