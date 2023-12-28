//
//  ObjectsNotifier.swift
//  SwiftPaymentsKit
//
//  Created by Oleg Home on 7/22/20.
//  Copyright © 2020 Oleg Home. All rights reserved.
//

import Foundation

final class ProcessCallbacksHolder<Object: Equatable, CallbackResult>: Equatable {
 
    typealias Handler = (CallbackResult)->()
    
    let object: Object
    private(set) var completionHandlers: [Handler] = []

    init(object: Object, handlers: [Handler] = []) {
        self.object = object
        self.completionHandlers = handlers
    }
    
    func addHandler(_ handler: @escaping Handler) {
        completionHandlers.append(handler)
    }
    
    func notifyWaiters(result: CallbackResult) {
        for completion in completionHandlers {
            completion(result)
        }
    }
    
    static func == (lhs: ProcessCallbacksHolder<Object, CallbackResult>, rhs: ProcessCallbacksHolder<Object, CallbackResult>) -> Bool {
        return lhs.object == rhs.object
    }
}
