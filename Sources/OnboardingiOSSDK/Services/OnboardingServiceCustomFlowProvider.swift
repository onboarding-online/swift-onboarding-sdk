//
//  OnboardingServiceCustomFlowProvider.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 23.02.2023.
//

import UIKit

public protocol OnboardingServiceCustomFlowProvider: AnyObject {
    func customViewControllerFor(screenId: String) -> UIViewController?
}



