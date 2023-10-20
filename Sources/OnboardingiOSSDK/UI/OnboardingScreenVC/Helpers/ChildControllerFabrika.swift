//
//  File.swift
//  
//
//  Created by Leonid Yuriev on 10.07.23.
//

import Foundation
import ScreensGraph

struct BaseScreenStruct {
    var baseScreen: BaseScreenProtocol
    var permissionAction: Action?
    var childController: BaseChildScreenGraphViewController
}

class ChildControllerFabrika {
    
    static func viewControllerFor(screen: Screen) -> BaseScreenStruct? {
        var baseScreen: BaseScreenProtocol?
        var permissionAction: Action?
        var childController: BaseChildScreenGraphViewController

        switch screen._struct {
        case .typeScreenImageTitleSubtitles(let value):
            
            baseScreen = saveMainScreenDataFor(value: value)
            childController = ScreenImageTitleSubtitleVC.instantiate(screenData: value)
        case .typeScreenProgressBarTitle(let value):
            
            baseScreen = saveMainScreenDataFor(value: value)
            childController = ScreenProgressBarTitleSubtitleVC.instantiate(screenData: value, screen: screen)
        case .typeScreenTableMultipleSelection(let value):
            
            baseScreen = saveMainScreenDataFor(value: value)
            childController = ScreenOneItemPerRowMultipleSelectionCollectionVC.instantiate(screenData: value)
        case .typeScreenTableSingleSelection(let value):
          
            baseScreen = saveMainScreenDataFor(value: value)
            childController = ScreenOneItemPerRowSingleSelectionCollectionVC.instantiate(screenData: value)
        case .typeScreenTitleSubtitleField(let value):
         
            baseScreen = saveMainScreenDataFor(value: value)
            childController = ScreenTitleSubtitleFieldVC.instantiate(screenData: value)
        case .typeScreenImageTitleSubtitleList(let value):
       
            baseScreen = saveMainScreenDataFor(value: value)
            childController = ScreenImageTitleSubtitleBulletsVC.instantiate(screenData: value)
        case .typeScreenTwoColumnMultipleSelection(let value):
           
            baseScreen = saveMainScreenDataFor(value: value)
            childController = ScreenCollectionMultipleSelectionVC.instantiate(screenData: value)
        case .typeScreenTwoColumnSingleSelection(let value):
           
            baseScreen = saveMainScreenDataFor(value: value)
            childController = ScreenCollectionSingleSelectionVC.instantiate(screenData: value)
        case .typeCustomScreen(_):
          
            childController = ScreenCollectionSingleSelectionVC.storyBoardInstance()
        case .typeScreenTooltipPermissions(let value):
           
            baseScreen = saveMainScreenDataFor(value: value)
            // TODO: check this controller
            permissionAction = value.permission?.action

            childController = ScreenImageTitleForNotificationVC.instantiate(screenData: value)
        case .typeScreenImageTitleSubtitleMultipleSelectionList(let value):
          
            baseScreen = saveMainScreenDataFor(value: value)
            childController = ScreenImageTitleSubtitleMultiSelectionListVC.instantiate(screenData: value)
        case .typeScreenImageTitleSubtitlePicker(let value):
            
            baseScreen = saveMainScreenDataFor(value: value)
            childController = ScreenPickerTitleSubtitleVC.instantiate(screenData: value)
        case .typeScreenTitleSubtitleCalendar(let value):
           
            baseScreen = saveMainScreenDataFor(value: value)
            childController = ScreenCalendarSelectionVC.instantiate(screenData: value)
        case .typeScreenSlider(let value):
            
            baseScreen = saveMainScreenDataFor(value: value)
            childController = ScreenImageTitleSubtitle1Subtitle2TimerVC.instantiate(screenData: value, screen: screen)
        case .typeScreenTitleSubtitlePicker(let value):
            
            baseScreen = saveMainScreenDataFor(value: value)
            childController = ScreenPickerTitleSubtitleVC.instantiate(screenData: value)
        }
        
        if let baseScreen = baseScreen {
            return BaseScreenStruct.init(baseScreen: baseScreen, permissionAction: permissionAction, childController: childController)
        }
        
        return nil
    }
    
    static func saveMainScreenDataFor(value: BaseScreenProtocol) -> BaseScreenProtocol? {
        return value
    }
    
}
