//
//  File.swift
//  
//
//  Copyright 2023 Onboarding.online on 18.03.2023.
//

import UIKit

protocol BaseViewControllerProtocol: UIViewController {
    func hideKeyboard()
}

extension BaseViewControllerProtocol where Self: UIViewController {
    func hideKeyboard() {
        view?.endEditing(true)
    }
}
