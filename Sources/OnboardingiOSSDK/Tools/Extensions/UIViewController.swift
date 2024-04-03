//
//  File.swift
//  
//
//  Copyright 2023 Onboarding.online on 17.03.2023.
//

import UIKit

extension UIViewController {
    
    class func nibInstance() -> Self {
        return self.init(nibName: String(describing: self).components(separatedBy: "<")[0], bundle: .module)
    }
    
    class func storyBoardInstance() -> Self {
        let name = String(describing: self).components(separatedBy: "<")[0]
        return  UIStoryboard(name: name, bundle: .module).instantiateViewController(withIdentifier: name) as! Self
    }
    
    func addChildViewController(_ childController: UIViewController, andEmbedToView containerView: UIView) {
        addChild(childController)
        childController.view.frame = containerView.bounds
        childController.view.embedInSuperView(containerView)
        childController.didMove(toParent: self)
    }
    
    func removeFromParentViewController() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    
}

import SafariServices

extension UIViewController {
    func showSafariWith(url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .pageSheet
        present(safariVC, animated: true)
    }
}
