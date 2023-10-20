//
//  OnboardingScreenDelegate.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 21.02.2023.
//

import Foundation
import ScreensGraph

protocol OnboardingScreenDelegate: AnyObject {
    func onboardingScreen(_ onboardingScreen: OnboardingScreenProtocol, didFinishWithScreenData screenData: ScreenData)
    func onboardingScreen(_ onboardingScreen: OnboardingScreenProtocol, updatedValue: Any)

    func onboardingScreen(_ onboardingScreen: OnboardingScreenProtocol, didRegisterUIEvent event: String, withParameters parameters: OnboardingData) // Analytics
}
