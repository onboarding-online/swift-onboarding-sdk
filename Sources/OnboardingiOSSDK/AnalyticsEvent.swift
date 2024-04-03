//
//  File.swift
//  
//
//  Created by Leonid Yuriev on 31.08.23.
//

import Foundation

public enum AnalyticsEvent: String {
    
    //    Parameters:

    //    projectId
    //    prefetchMode
    //    environment
    case startResourcesLoading = "start resources loading"

    //    Parameters:
    
    //    jsonLoadingTime
    //    assetsLoadingTime
    
    //    prefetchMode
    //    projectName
    //    projectId
    //    onboardingName
    //    onboardingId
    case jsonAndPrefetchModeAssetsLoaded = "json and assets loaded"
    
    //    Parameters:
    
    //    prefetchMode
    //    onboardingSourceType: .url / .jsonName
    //    projectName
    //    projectId
    //    onboardingName
    //    onboardingId
    
    // if onboardingSourceType == .url {
    //   timeout
    //   url
    // } if onboardingSourceType == .jsonName  else {
    //   jsonName
    //   time
    // }
    case startOnboarding = "start onboarding with parameters"
    
    //    Parameters:
    //    screenID
    //    screenName
    //    userInputValue
    case userUpdatedValue = "user updated value"

    //    Parameters:
    //    screenID
    //    screenName
    case screenDidAppear = "screen appeared"
    
    //    Parameters:
    //    screenID
    //    screenName
    //    userInputValue
    //    nextScreenId
    case screenDisappeared = "screen disappeared"
    
    //    Parameters:
    //    screenID
    //    screenName
    case rightNavbarButtonPressed = "right navbar button pressed"
    //    Parameters:
    //    screenID
    //    screenName
    case leftNavbarButtonPressed = "left navbar button pressed"
    
    //    Parameters:
    //    screenID
    //    screenName
    case firstFooterButtonPressed = "first footer button pressed"
    //    Parameters:
    //    screenID
    //    screenName
    case secondFooterButtonPressed = "second footer button pressed"
    
    //    Parameters:
    //    screenID
    //    screenName
    case switchedToNewScreenOnTimer = "switched to a new screen on a timer"
    
    //    Parameters:
    //    abtestName
    //    abtestThreshold
    case abTestLoaded = "A/B test loaded"
    
    //    Parameters:
    //    screenName
    //    screenID
    //    customScreenLabelsValue
    case customScreenRequested = "custom screen appearance request"
    
    //    Parameters:
    //    screenName
    //    screenID
    case customScreenNotImplementedInCodeOnboardingFinished = "could not find custom screen"
    
    //    Parameters:
    //    screenName
    //    screenID
    //    customScreenUserInputValue
    case customScreenDisappeared  = "custom screen disappeared"
    
    //    Parameters:
    //    userInputValues
    case onboardingFinished = "onboarding finished"
    
    //    Parameters:
    //    screenID
    //    screenName
    //    permissionType: . adsPermission / .pushNotificationPermission
    case permissionRequested = "permission requested"
    
    //    Parameters:
    //    screenID
    //    screenName
    //    permissionType: . adsPermission / .pushNotificationPermission
    //    permissionGranted: true / false
    case permissionResponseReceived = "a response to the permission request was received"
    
    //    Parameters:
    //    time
    //    assetsLoadedSuccess
    case allAssetsLoaded = "all assets loaded"
    
    /// Paywalls
    //    Parameters:
    //    screenID
    //    screenName
    case paywallAppeared
    //    Parameters:
    //    screenID
    //    screenName
    case paywallDisappeared
    //    Parameters:
    //    screenID
    //    screenName
    case paywallCloseButtonPressed
    //    Parameters:
    //    screenID
    //    screenName
    
    case restorePurchaseButtonPressed
    //    Parameters:
    //    screenID
    //    screenName
    //    url
    case tcButtonPressed
    //    Parameters:
    //    screenID
    //    screenName
    //    url
    case ppButtonPressed
    //    Parameters:
    //    screenID
    //    screenName
    case productSelected
    //    Parameters:
    //    screenID
    //    screenName
    //    selectedProductId
    case purchaseButtonPressed
    //    Parameters:
    //    screenID
    //    screenName
    //    productId
    //    paymentsInfo
    case productPurchased
    //    Parameters:
    //    screenID
    //    screenName
    //    productId
    //    transactionId
    case purchaseCanceled
    //    Parameters:
    //    screenID
    //    screenName
    //    productId
    case purchaseFailed
    //    Parameters:
    //    screenID
    //    screenName
    //    productId
    case productRestored
    
// System events
    
    //    Parameters:
    //    jsonName
    case localJSONNotFound = "didn't find json file"
    
    //    Parameters:
    //    jsonName
    case wrongJSONStruct = "wrong json struct"
    
    //    Parameters:
    //    time
    case JSONLoadedFromURLButTimeoutOccurred = "json was loaded but timed out"
    
    //    Parameters:
    //    error
    case JSONLoadingFailure = "json loading error"
    
    //    Parameters:
    //    edge
    case nextScreenEdgeWithCondition = "next screen edge with condition"
    
    //    Parameters:
    //    edge
    case nextScreenEdgeWithoutCondition = "next screen edge without condition"
    
    //    Parameters:
    //    edge
    case nextScreenEdgeForWrongConditions = "there are no right conditions. Random edge for wrong condition used!!!"
    
    case paymentServiceNotFound = "paymentServiceNotFound"
}

public enum AnalyticsEventParams: String {
    
    case abtestName = "abtestName"
    case abtestThreshold = "abtestThreshold"
    case abtestGroup = "abtestGroup"
    case abtestId = "abtestId"
    
    case projectName = "project name"
    case projectId = "project id"
    case onboardingName = "onboarding name"
    case onboardingId = "onboarding id"

    case screenID = "screenID"
    
    case screenName = "screenName"
    
    case userInputValue = "userInputValue"
    
    case customScreenUserInputValue = "custom screen user input value"
    case customScreenLabelsValue = "custom screen labels values"

    case nextScreenId = "nextScreenId"
  
    case prefetchMode = "prefetchMode"
    
    case edge = "edge"
    
    case jsonName = "jsonName"
    
    case url = "url"
    
    case time = "download time"
    
    case assetsLoadingTime = "assets loading time"
    case jsonLoadingTime = "json loading time"
    case environment = "environment"
    case assetsLoadedSuccess = "assetsLoadedSuccess"
    
    case error = "error"
    
    case timeout = "timeout"
    
    case buttonTitle = "buttonTitle"
    
    case onboardingSourceType = "onboardingSourceType"
    
    case userInputValues = "userInputValues"
    
    case permissionType = "permissionType"

    case adsPermission = "adsPermission"

    case pushNotificationPermission = "pushNotificationPermission"
    
    case permissionGranted = "permissionGranted"
    
    
    case selectedProductId
    
    case productId
    
    case paymentsInfo
    
    case transactionId

    case hasActiveSubscription

}
