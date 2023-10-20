//
//  Bundle.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 04.06.2023.
//

import Foundation

extension Bundle {
    var releaseVersionNumber: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }
}
