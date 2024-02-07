//
//  OnboardingNavigationController.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 19.02.2023.
//

import UIKit

protocol OnboardingNavigationControllerDelegate: AnyObject {
    
}

final class OnboardingNavigationController: UINavigationController {
    
    weak var onboardingDelegate: OnboardingNavigationControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupDelegates()
    }
    
}

// MARK: - UINavigationControllerDelegate
extension OnboardingNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
    }
}

// MARK: - Private methods
private extension OnboardingNavigationController {
    
    @objc func handleSwipeGesture(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began:
            return
            /// To check when interactive gesture wasn't finished
//            self.transitionCoordinator?.notifyWhenInteractionChanges({ [weak self] context in
//                if context.completionVelocity < 0,
//                   let viewController = context.viewController(forKey: .from) {
//
//                }
//            })
        case .changed:
            return 
//            guard let panGesture = gesture as? UIPanGestureRecognizer else { return }
//            
//            let translation = panGesture.translation(in: view)
//            let progress = abs(translation.x / view.bounds.width)
        default:
            return
        }
    }
    
}

// MARK: - Setup methods
private extension OnboardingNavigationController {
    
    func setup() {
        setupUI()
    }
    
    func setupDelegates() {
        interactivePopGestureRecognizer?.isEnabled = false
        delegate = self
        interactivePopGestureRecognizer?.addTarget(self, action: #selector(handleSwipeGesture))
    }
    
    func setupUI() {
        let appearance = UINavigationBar.appearance(whenContainedInInstancesOf: [OnboardingNavigationController.self])
        
        if #available(iOS 13.0, *) {
            appearance.barTintColor = .systemBackground
            appearance.tintColor = .label
        } else {
            appearance.barTintColor = .white
            appearance.tintColor = .black
        }
        appearance.isTranslucent = true
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black,
                                          .font: UIFont.systemFont(ofSize: 18, weight: .regular)]
    }
    
}
