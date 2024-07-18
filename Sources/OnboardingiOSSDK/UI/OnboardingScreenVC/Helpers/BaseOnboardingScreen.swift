//
//  BaseOnboardingScreen.swift
//  OnboardingOnline
//
//  Created by Leonid Yuriev on 29.06.23.
//

import Foundation
import UIKit
import ScreensGraph

public class BaseOnboardingScreen: UIViewController {
    
    private var backgroundImageView: UIImageView?
    var footerBottomConstraint: NSLayoutConstraint?
    var backgroundView: UIView!
    private var videoBackground: VideoBackground?


    public override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = true
        addKeyboardListeners()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    
        removeKeyboardListener()
    }
    
}

extension BaseOnboardingScreen {
    
    func updateBackground(image: BaseImage?, useLocalAssetsIfAvailable: Bool) {
        if let image = image?.loadCashedImage(useLocalAssetsIfAvailable: useLocalAssetsIfAvailable) {
            setBackgroundImage(image)
        } else {
            Task { @MainActor in
                if let image = await image?.loadImage(useLocalAssetsIfAvailable: useLocalAssetsIfAvailable) {
                    setBackgroundImage(image)
                }
            }
        }
    }
    
    private func setBackgroundImage(_ image: UIImage) {
        let backgroundImageView = self.createBackgroundImageView()
        backgroundImageView.image = image
    }
    
    private func createBackgroundImageView() -> UIImageView {
        if let backgroundImageView = self.backgroundImageView {
            self.view.insertSubview(backgroundImageView, at: 0)
            return backgroundImageView
        } else {
            let backgroundImageView = UIImageView(frame: self.view.frame)
            backgroundImageView.contentMode = .scaleAspectFill
            backgroundImageView.clipsToBounds = true
            self.backgroundImageView = backgroundImageView
            backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.insertSubview(backgroundImageView, at: 0)
            return backgroundImageView
        }
    }
    
    func setupBackgroundFor(screenId: String,
                            using preparationService: VideoPreparationService) {
        if let status = preparationService.getStatusFor(screenId: screenId),
           case .ready(let preparedData) = status {
            playVideoBackgroundWith(preparedData: preparedData)
        } else {
            preparationService.observeScreenId(screenId) { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .undefined, .preparing:
                        return
                    case .failed:
                        self?.backgroundView.backgroundColor = .white
                    case .ready(let preparedData):
                        self?.playVideoBackgroundWith(preparedData: preparedData)
                    }
                }
            }
        }
    }
    
    func playVideoBackgroundWith(preparedData: VideoBackgroundPreparedData) {
        let videoBackgroundHandler: VideoBackground
        if let videoBackground = self.videoBackground {
            videoBackgroundHandler = videoBackground
        } else {
            videoBackgroundHandler = VideoBackground()
            self.videoBackground = videoBackgroundHandler
        }
        
        videoBackgroundHandler.play(in: self.backgroundView,
                                    using: preparedData)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UIView.animate(withDuration: 0.5) {
                self.backgroundImageView?.alpha = 0
            } completion: { _ in
                self.backgroundImageView?.removeFromSuperview()
                self.backgroundImageView?.alpha = 1
            }
        }
    }
    
}

private extension BaseOnboardingScreen {

    func addKeyboardListeners() {
        // Notifications for when the keyboard opens/closes
         NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        // Move the view only when the usernameTextField or the passwordTextField are being edited
        if let footerConstraint = footerBottomConstraint {
            moveViewWithKeyboard(notification: notification, viewBottomConstraint: footerConstraint, keyboardWillShow: true)
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        if let footerConstraint = footerBottomConstraint {
            moveViewWithKeyboard(notification: notification, viewBottomConstraint: footerConstraint, keyboardWillShow: false)
        }
    }
    
    func moveViewWithKeyboard(notification: NSNotification, viewBottomConstraint: NSLayoutConstraint, keyboardWillShow: Bool) {
        // Keyboard's size
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let keyboardHeight = keyboardSize.height
        
        // Keyboard's animation duration
        let keyboardDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        
        // Keyboard's animation curve
        let keyboardCurve = UIView.AnimationCurve(rawValue: notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! Int)!
        
        // Change the constant
        if keyboardWillShow {
            let bottomSafeAreaConstraint = self.view?.window?.safeAreaInsets.bottom ?? 0
            let safeAreaExists = (bottomSafeAreaConstraint != 0) // Check if safe area exists
            viewBottomConstraint.constant = keyboardHeight + (safeAreaExists ? -bottomSafeAreaConstraint : 0)
        }else {
            viewBottomConstraint.constant = 32
        }
        
        // Animate the view the same way the keyboard animates
        let animator = UIViewPropertyAnimator(duration: keyboardDuration, curve: keyboardCurve) { [weak self] in
            // Update Constraints
            self?.view.layoutIfNeeded()
        }
        
        // Perform the animation
        animator.startAnimation()
    }
    
    func removeKeyboardListener() {
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
}
