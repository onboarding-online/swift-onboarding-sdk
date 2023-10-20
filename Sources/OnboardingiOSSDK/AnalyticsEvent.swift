//
//  File.swift
//  
//
//  Created by Leonid Yuriev on 31.08.23.
//

import Foundation

public enum AnalyticsEvent: String {
    
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
    //    creenName
    //    userInputValue
    case userUpdatedValue = "user updated value"

    //    Parameters:
    //    screenID
    //    creenName
    case screenDidAppear = "screen appeared"
    
    //    Parameters:
    //    screenID
    //    creenName
    //    userInputValue
    //    nextScreenId
    case screenDisappeared = "screen disappeared"
    
    //    Parameters:
    //    screenID
    //    creenName
    case rightNavbarButtonPressed = "right navbar button pressed"
    //    Parameters:
    //    screenID
    //    creenName
    case leftNavbarButtonPressed = "left navbar button pressed"
    
    //    Parameters:
    //    screenID
    //    creenName
    case firstFooterButtonPressed = "first footer button pressed"
    //    Parameters:
    //    screenID
    //    creenName
    case secondFooterButtonPressed = "second footer button pressed"
    
    //    Parameters:
    //    screenID
    //    creenName
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
    case customScreenDisappeared  = "custom screen disapeared"
    
    //    Parameters:
    //    userInputValues
    case onboardingFinished = "onboarding finished"
    
    //    Parameters:
    //    screenID
    //    creenName
    //    pemitionType: . adsPemition / .pushNotificationPemition
    case permissionRequested = "permission requested"
    
    //    Parameters:
    //    screenID
    //    creenName
    //    pemitionType: . adsPemition / .pushNotificationPemition
    //    permissionGranted: true / false
    case permissionResponsesReceived = "a response to the permission request was received"
    
// System events
    
    //    Parameters:
    //    jsonName
    case localJSONNotFound = "didn't find json file"
    
    //    Parameters:
    //    jsonName
    case wrongJSONStruct = "wrong json struct"
    
    //    Parameters:
    //    time
    case JSONLoadedFromURLButTimeoutOccured = "json was loaded but timed out"
    
    //    Parameters:
    //    error
    case JSONLoadingFalure = "json loading error"
    
    //    Parameters:
    //    edge
    case nextScreenEdgeWithCondition = "next screen edge with condition"
    
    //    Parameters:
    //    edge
    case nextScreenEdgeWithoutCondition = "next screen edge without condition"
    
    //    Parameters:
    //    edge
    case nextScreenEdgeForWrongConditions = "there are no right conditions. Random edge for wrong condition used!!!"
        
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
        
    case error = "error"
    
    case timeout = "timeout"
    
    case buttonTitle = "buttonTitle"
    
    case onboardingSourceType = "onboardingSourceType"
    
    case userInputValues = "userInputValues"
    
    case permissionType = "permissionType"

    case adspermission = "adsPemition"

    case pushNotificationpermission = "pushNotificationPemition"
    
    case permissionGranted = "permissionGranted"

}
