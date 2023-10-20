//
//  File.swift
//  
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import UIKit

// MARK: - BackgroundTasksServiceProtocol
protocol BackgroundTasksServiceProtocol {
    func startBackgroundTask()
    func stopBackgroundTask()
}

// MARK: - BackgroundTasksService
final class BackgroundTasksService {
    
    static let shared = BackgroundTasksService()
    
    private var backgroundTask: UIBackgroundTaskIdentifier?
    private var counter = 0
    
    func startTrackAppState() {
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func willResignActive() {
        startBackgroundTask()
    }
    
    @objc private func didBecomeActive() {
        stopBackgroundTask()
    }
}

// MARK: - BackgroundTasksServiceProtocol
extension BackgroundTasksService: BackgroundTasksServiceProtocol {
    func startBackgroundTask() {
        ensureOnMainQueue {
            UIApplication.shared.isIdleTimerDisabled = true
            counter += 1
            setupBackgroundTask()
        }
    }
    
    func stopBackgroundTask() {
        ensureOnMainQueue {
            counter -= 1
            counter = max(0, counter) // Make sure counter always >= 0
            if counter == 0 {
                UIApplication.shared.isIdleTimerDisabled = false
                if let task = self.backgroundTask {
                    UIApplication.shared.endBackgroundTask(task)
                }
                
                self.backgroundTask = nil
            }
        }
    }
}

// MARK: - Private methods
fileprivate extension BackgroundTasksService {
    func setupBackgroundTask() {
        guard backgroundTask == nil else { return }
        
        let backgroundTask = UIApplication.shared.beginBackgroundTask {
            self.stopBackgroundTask()
        }
        setBackgroundTask(backgroundTask)
    }
    
    func setBackgroundTask(_ backgroundTask: UIBackgroundTaskIdentifier) {
        self.backgroundTask = backgroundTask
    }
    
    func ensureOnMainQueue(block: ()->()) {
        if Thread.current.isMainThread {
            block()
        } else {
            DispatchQueue.main.sync {
                block()
            }
        }
    }
}
