//
//  File.swift
//  
//
//  Copyright 2023 Onboarding.online on 17.03.2023.
//

import Foundation
import ScreensGraph
import UIKit

typealias EmptyCallback = ()->()
typealias BoolCallback = (Bool)->()
typealias IntCallback = (Int)->()
public typealias OnboardingData = [String: Any]
public typealias OnboardingDataCallback = (OnboardingData?)->()

public typealias GenericResult<T> = Result<T, GenericError>
public typealias GenericResultCallback<T> = (GenericResult<T>) -> ()

public typealias ScreenData = Action?
public typealias CustomScreenCallback = ((Screen, UINavigationController?) -> ())
public typealias CustomScreenUserInputValue = [String: CustomScreenInputValue]

public typealias PermissionRequestCallback = ((Screen, ScreenPermissionType) -> ())


public typealias AnalyticsEventParameters = [AnalyticsEventParams : Any]
public typealias AnalyticsEventCallback = ((AnalyticsEvent, AnalyticsEventParameters?) -> ())

public typealias OnboardingResultCallback = (OnboardingData?) -> ()

let mainQueue = DispatchQueue.main

protocol ImageProtocol {
    var image: Image { get }
}

protocol ImageOptionalProtocol {
    var image: Image? { get }
}

protocol PickerItem: Equatable {
    var title: String { get }
}

protocol PickerScreenProtocol {
    var picker: Picker { get }
    var title: Text { get }
    var subtitle: Text { get }
    var useLocalAssetsIfAvailable: Bool { get }
}

protocol NavigationBarProtocol {
    var navigationBar: NavigationBar { get }
}

protocol FooterProtocol {
    var footer: Footer { get }
}

protocol BaseScreenStyleProtocol {
    var styles: BasicScreenBlock { get }
}

protocol PaywallBaseScreenStyleProtocol {
    var styles: ScreenBasicPaywallBlock { get }
    var media: Media? { get }
    var useLocalAssetsIfAvailable: Bool { get }
}

protocol MediaProtocol {
    var media: Media? { get }
    var useLocalAssetsIfAvailable: Bool { get }
}

protocol PermissionProtocol {
    var permission: RequestPermission? { get }
}

protocol TimerActionProtocol {
    var timer: ScreenTimer? { get }
}

protocol BaseConfigBlockProtocol {
    var animationEnabled: Bool { get }
    var useLocalAssetsIfAvailable: Bool { get }
}

protocol BaseScreenProtocol: NavigationBarProtocol, FooterProtocol, BaseScreenStyleProtocol, PermissionProtocol, TimerActionProtocol, BaseConfigBlockProtocol {
}

protocol PermissionActionProtocol {
    var action: Action { get }
}

protocol Assetable : ImageProtocol, BaseScreenProtocol {}

extension ScreenSlider: BaseScreenProtocol { }

extension ItemTypeSelection: ImageProtocol { }


extension ItemTypeRegular: ImageProtocol {}

struct ImageList: ImageProtocol {
    let image: Image
}

extension ScreenTitleSubtitlePicker: BaseScreenProtocol, PickerScreenProtocol { }

extension SlideContent: ImageProtocol { }

extension ScreenImageTitleSubtitleList: Assetable { }

extension ScreenImageTitleSubtitleMultipleSelectionList: Assetable { }

extension ScreenTooltipPermissions: BaseScreenProtocol { }

extension ScreenImageTitleSubtitlePicker: Assetable, PickerScreenProtocol {}

extension ScreenImageTitleSubtitles: Assetable { }

extension ScreenProgressBarTitle: BaseScreenProtocol { }

extension ScreenTableMultipleSelection: BaseScreenProtocol, MediaProtocol { }

extension ScreenTableSingleSelection: BaseScreenProtocol, MediaProtocol { }

extension ScreenTitleSubtitleCalendar: BaseScreenProtocol { }

extension ScreenTitleSubtitleField: BaseScreenProtocol { }

extension ScreenTwoColumnMultipleSelection: BaseScreenProtocol, MediaProtocol { }

extension ScreenTwoColumnSingleSelection: BaseScreenProtocol, MediaProtocol { }

extension ScreenBasicPaywall:  PaywallBaseScreenStyleProtocol { }




extension Screen {
    
    public func customScreenValue() -> CustomScreen? {
        switch self._struct {
        case .typeCustomScreen(let value):
            return value
        default:
            return nil
        }
    }
    
    public func isCustomScreen() -> Bool {
        if customScreenValue() != nil {
            return true
        }
         
        return false
    }
    
    public func paywallScreenValue() -> ScreenBasicPaywall? {
        switch self._struct {
        case .typeScreenBasicPaywall(let value):
            return value
        default:
            return nil
        }
    }
    
    public func isPaywallScreen() -> Bool {
        if paywallScreenValue() != nil {
            return true
        }
         
        return false
    }
    
    
}

protocol JSONEncodable {
    
}
