//
//  OnboardingScreenProtocol.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 21.02.2023.
//

import UIKit
import ScreensGraph

protocol OnboardingScreenProtocol: UIViewController {
    var screen: Screen! { get set }
    var value: Any? { get set }
    var permissionValue: Bool? { get set }
    var delegate: OnboardingScreenDelegate? { get set } // Should be weak 
}

protocol OnboardingChildScreenDelegate: AnyObject {
    func onboardingChildScreenUpdate(value: Any?, description: String?, logAnalytics: Bool)
    func onboardingChildScreenPerform(action: Action)
}

protocol OnboardingBodyChildScreenProtocol: UIViewController {
    var delegate: OnboardingChildScreenDelegate? { get set }
}

struct OnboardingScreenValue {
    let valueType: ValueTypes
    var value: Any?
}
