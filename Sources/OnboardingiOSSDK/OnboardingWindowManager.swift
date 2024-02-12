//
//  OnboardingWindowManager.swift
//  OnboardingiOSExampleApp
//
//  Created by Oleg Kuplin on 22.11.2023.
//

import UIKit

protocol OnboardingWindowManagerProtocol {
    func getWindows() -> [UIWindow]
    func getActiveWindow() -> UIWindow?
    func getCurrentWindow() -> UIWindow?
    func setNewRootViewController(_ viewController: UIViewController,
                                  in window: UIWindow,
                                  animated: Bool,
                                  completion: (()->())?)
}

final class OnboardingWindowManager {
    
    static let shared = OnboardingWindowManager()
    
    private var didSetKeyWindow = false
    
    init() {
        didSetKeyWindow = getKeyWindow() != nil
        NotificationCenter.default.addObserver(self, selector: #selector(keyWindowDidChange), name: UIWindow.didBecomeKeyNotification, object: nil)
    }
    
    @objc func keyWindowDidChange() {
        didSetKeyWindow = true
    }
    
}

// MARK: - Open methods
extension OnboardingWindowManager: OnboardingWindowManagerProtocol {
    
    func getWindows() -> [UIWindow] {
        UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
    }
    
    func getActiveWindow() -> UIWindow? {
        let windows = getWindows()
        if let keyWindow = windows.first(where: \.isKeyWindow) {
            return keyWindow
        } else if !didSetKeyWindow {
            return windows.first
        }
        return nil
    }
    
    func getCurrentWindow() -> UIWindow? {
        if let activeWindow = getActiveWindow() {
            return activeWindow
        } else if UIApplication.shared.applicationState != .active {
            return getWindows().first
        }
        return nil
    }
    
    func setNewRootViewController(_ viewController: UIViewController,
                                  in window: UIWindow,
                                  animated: Bool = true,
                                  completion: (()->())? = nil) {
        let previousController = window.rootViewController
        
        if let snapshot = window.snapshotView(afterScreenUpdates: true),
           animated {
            viewController.view.addSubview(snapshot)
            window.rootViewController = viewController
            
            let animationDuration: TimeInterval = 0.3
            
            UIView.animate(withDuration: animationDuration, animations: {
                snapshot.layer.opacity = 0
                snapshot.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.2)
            }, completion: { _ in
                snapshot.removeFromSuperview()
                previousController?.dismiss(animated: false)
                completion?()
            })
        } else {
            window.rootViewController = viewController
            completion?()
        }
    }
}

// MARK: - Private methods
private extension OnboardingWindowManager {
    
    func getKeyWindow() -> UIWindow? {
        getWindows().first(where: \.isKeyWindow)
    }
    
}
