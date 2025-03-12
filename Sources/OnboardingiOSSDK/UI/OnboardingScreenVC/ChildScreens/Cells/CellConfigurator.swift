//
//  CellConfigurator.swift
//  OnboardingOnline
//
//  Created by Leonid Yuriev on 3.07.23.
//

import UIKit
import ScreensGraph

protocol BoxProtocol {
    var paddingLeft: Double? { get set }
    var paddingRight: Double? { get set }
    var paddingTop: Double? { get set }
    var paddingBottom: Double? { get set }
}

extension BoxBlock: BoxProtocol { }
extension ListBlock: BoxProtocol { }

protocol CellConfiguratorProtocol {
    
    var allItemsHorizontalStackViewSpacing: CGFloat { get set }
    var labelsVerticalStackViewSpacing: CGFloat { get set }

    var imageWidth: CGFloat { get set }
    var imageHeigh: CGFloat { get set }
    var checkboxSize: CGFloat { get set }
    
    var containerLeading: CGFloat { get set }
    var containerTrailing: CGFloat { get set }
    var containerTop: CGFloat { get set }
    var containerBottom: CGFloat { get set }
    
    func calculateHeightFor(titleText: Text?,
                                   subtitleText: Text?,
                                   itemType: Any,
                                   containerWidth: CGFloat,
                                   horizontalInset: CGFloat,
                                   isSelected: Bool?) -> CGFloat
    
    func isCheckboxHiddenFor(itemType: Any) -> Bool
    
    func isImageHiddenFor(itemType: Any) -> Bool
}

class CellConfigurator: CellConfiguratorProtocol {
    var allItemsHorizontalStackViewSpacing: CGFloat = 16
    var labelsVerticalStackViewSpacing: CGFloat = 8

    var imageWidth: CGFloat = 24
    var imageHeigh: CGFloat = 24

    var checkboxSize: CGFloat = 24
    
    var containerLeading: CGFloat = 24
    var containerTrailing: CGFloat = 24
    var containerTop: CGFloat = 16
    var containerBottom: CGFloat = 16
    
    var distanceFromTitlesToItems: CGFloat = 16
    
    var spacingBetweenTitleLabels: CGFloat = 0
    
    var spacingBetweenItems: CGFloat = OnboardingService.shared.spacingBetweenItems
    
    var currentItem: ItemTypeSelection? = nil

    func setupImage(settings: ImageBlock?) {
        guard let imageWidth = settings?.width, let imageHeight = settings?.width else { return }
        
        self.imageWidth = imageWidth
        self.imageHeigh = imageHeight
    }
    
    func setupItemsConstraintsWith(box: BoxProtocol?) {
        guard let box = box else { return }
        
        if let paddingLeft =  box.paddingLeft?.cgFloatValue {
            self.containerLeading = paddingLeft
        } else {
            self.containerLeading = 0.0
        }
        
        if let paddingRight =  box.paddingRight?.cgFloatValue {
            self.containerTrailing = paddingRight
        } else {
            self.containerTrailing = 0.0
        }

        if let paddingTop =  box.paddingTop?.cgFloatValue {
            self.containerTop = paddingTop
        } else {
            self.containerTop = 0.0
        }
        
        if let paddingBottom =  box.paddingBottom?.cgFloatValue {
            self.containerBottom = paddingBottom
        } else {
            self.containerBottom = 0.0
        }
    }
    
    func calculateHeightFor1(titleText: Text?,
                                   subtitleText: Text?,
                                   itemType: Any,
                                   containerWidth: CGFloat,
                            horizontalInset: CGFloat, isSelected: Bool? = nil) -> CGFloat {
        // Calculate effective width for labels heights calculation
        var labelWidth = containerWidth - containerLeading - containerTrailing
        
        var labelTitleWidth: CGFloat = 0.0
        var labelSubtitleWidth: CGFloat = 0.0
        
        var titlePaddingHeight: CGFloat = 0.0
        var subtitlePaddingHeight: CGFloat = 0.0


        if let titleStyle = titleText?.box.styles {
            labelTitleWidth = labelWidth - titleStyle.paddingLeft.cgFloatValue - titleStyle.paddingRight.cgFloatValue
            titlePaddingHeight = titleStyle.paddingTop.cgFloatValue  + titleStyle.paddingBottom.cgFloatValue
            
            if let titleStyle = titleText?.styles {
                labelTitleWidth = labelTitleWidth - titleStyle.paddingLeft.cgFloatValue - titleStyle.paddingRight.cgFloatValue
                titlePaddingHeight  += titleStyle.paddingTop.cgFloatValue  + titleStyle.paddingBottom.cgFloatValue
            }
        }
        
        if let titleStyle = subtitleText?.box.styles {
            labelSubtitleWidth = labelWidth - titleStyle.paddingLeft.cgFloatValue - titleStyle.paddingRight.cgFloatValue
            subtitlePaddingHeight = titleStyle.paddingTop.cgFloatValue + titleStyle.paddingBottom.cgFloatValue
            
            if let titleStyle = subtitleText?.styles {
                labelSubtitleWidth = labelSubtitleWidth - titleStyle.paddingLeft.cgFloatValue - titleStyle.paddingRight.cgFloatValue
                subtitlePaddingHeight += titleStyle.paddingTop.cgFloatValue  + titleStyle.paddingBottom.cgFloatValue
            }
        }

        
        if !isImageHiddenFor(itemType: itemType) {
            labelWidth -= imageWidth
            labelTitleWidth -= imageWidth
            labelSubtitleWidth -= imageWidth

        } else {
            self.imageWidth = 0
            self.imageHeigh = 0
        }
        
        if !isCheckboxHiddenFor(itemType: itemType) {
            labelWidth -= checkboxSize
            labelTitleWidth -= checkboxSize
            labelSubtitleWidth -= checkboxSize
        }
        
        //Calculate labels height
        var totalLabelsBlockHeight = 0.0
        var subtitleHeight: CGFloat = 0.0
        

        let titleHeight = titleText?.textHeightBy(textWidth: labelTitleWidth) ?? 0.0

        if !(titleText?.textByLocale() ?? "").isEmpty {
            totalLabelsBlockHeight += titleHeight > 0.0 ? titleHeight : 0
            totalLabelsBlockHeight += titlePaddingHeight
        }

        
        if !isSubtitleHiddenFor(itemType: itemType)  {
            if !(subtitleText?.textByLocale() ?? "").isEmpty {
                subtitleHeight = subtitleText?.textHeightBy(textWidth: labelSubtitleWidth) ?? 0.0
                if subtitleHeight > 0.0  {
                    totalLabelsBlockHeight += subtitleHeight
                    totalLabelsBlockHeight += subtitlePaddingHeight
                }
            }
        }

                
        //Get max elemets height for cell height
        var maxHeight = totalLabelsBlockHeight > imageHeigh ? totalLabelsBlockHeight : imageHeigh
        maxHeight = maxHeight > checkboxSize ? maxHeight : checkboxSize
        
        let cellHeight = maxHeight + containerTop + containerBottom
        
        return cellHeight
    }
    
    func calculateHeightFor(titleText: Text?,
                                   subtitleText: Text?,
                                   itemType: Any,
                                   containerWidth: CGFloat,
                            horizontalInset: CGFloat, isSelected: Bool? = nil) -> CGFloat {
        // Calculate effective width for labels heights calculation
        var labelWidth = containerWidth - containerLeading - containerTrailing - 8
        
        if !isImageHiddenFor(itemType: itemType) {
            labelWidth -= (imageWidth + allItemsHorizontalStackViewSpacing)
        } else {
            self.imageWidth = 0
            self.imageHeigh = 0
        }
        
        if !isCheckboxHiddenFor(itemType: itemType) {
            labelWidth -= (checkboxSize + allItemsHorizontalStackViewSpacing)
        }
        
        //Calculate labels height
        var totalLabelsBlockHeight = 0.0
        var subtitleHeight: CGFloat = 0.0
        

        let titleHeight = titleText?.textHeightBy(textWidth: labelWidth) ?? 0.0

        totalLabelsBlockHeight += titleHeight > 0.0 ? titleHeight : 0
        
        if !isSubtitleHiddenFor(itemType: itemType) {
            subtitleHeight = subtitleText?.textHeightBy(textWidth: labelWidth) ?? 0.0
            totalLabelsBlockHeight += subtitleHeight > 0.0 ? subtitleHeight : 0
        }
//      Could be enabled for cells with dynamic height for selected state
//        if let isCellSelected = isSelected {
//            if isCellSelected {
//                subtitleHeight = subtitleText?.textHeightBy(textWidth: labelWidth) ?? 0.0
//                totalLabelsBlockHeight += subtitleHeight > 0.0 ? subtitleHeight : 0
//            }
//        } else {
//            if !isSubtitleHiddenFor(itemType: itemType) {
//                subtitleHeight = subtitleText?.textHeightBy(textWidth: labelWidth) ?? 0.0
//                totalLabelsBlockHeight += subtitleHeight > 0.0 ? subtitleHeight : 0
//            }
//        }

        //Add gap between labels if there are 2 labels
        if titleHeight > 0.0 && subtitleHeight > 0.0 {
            totalLabelsBlockHeight += labelsVerticalStackViewSpacing
        }
                
        //Get max elemets height for cell height
        var maxHeight = totalLabelsBlockHeight > imageHeigh ? totalLabelsBlockHeight : imageHeigh
        maxHeight = maxHeight > checkboxSize ? maxHeight : checkboxSize
        
        let cellHeight = maxHeight + containerTop + containerBottom
        
        return cellHeight
    }
    
    func isCheckboxHiddenFor(itemType: Any) -> Bool {
        
        if let type = itemType as? MultipleSelectionListItemType {
            return isCheckboxHiddenFor(itemType: type)
        }
        
        if let type = itemType as? SingleSelectionListItemType {
            return isCheckboxHiddenFor(itemType: type)
        }
        
        return false
    }
    
    func isImageHiddenFor(itemType: Any) -> Bool {
        
        if let type = itemType as? MultipleSelectionListItemType {
            return isImageHiddenFor(itemType: type)
        }
        
        if let type = itemType as? SingleSelectionListItemType {
            return isImageHiddenFor(itemType: type)
        }
        
        return false
    }
    
    func isSubtitleHiddenFor(itemType: Any) -> Bool {
        
        if let type = itemType as? MultipleSelectionListItemType {
            return isSubtitleHiddenFor(itemType: type)
        }
        
        if let type = itemType as? SingleSelectionListItemType {
            return isSubtitleHiddenFor(itemType: type)
        }
        
        return false
    }
    
    func isImageHiddenFor(itemType: MultipleSelectionListItemType) -> Bool {
        switch itemType {
        case .imageTitle:
            return false
        case .titleImage:
            return false
        case .imageTitleSubtitleCheckbox:
            return false
        case .checkboxTitleSubtitleImage:
            return false
        case .imageTitleCheckbox:
            return false
        case .checkboxTitleImage:
            return false
        case .titleCheckbox:
            return true
        case .checkboxTitle:
            return true
        case .imageTitleSubtitle:
            return false
        case .titleSubtitleImage:
            return false
        case .titleSubtitle:
            return true
        case .title:
            return true
        case .titleSubtitleCheckbox:
            return true
        case .checkboxTitleSubtitle:
            return true
        }
    }
    
    func isSubtitleHiddenFor(itemType: MultipleSelectionListItemType) -> Bool {
        switch itemType {
        case .imageTitle:
            return true
        case .titleImage:
            return true
        case .imageTitleSubtitleCheckbox:
            return false
        case .checkboxTitleSubtitleImage:
            return false
        case .imageTitleCheckbox:
            return true
        case .checkboxTitleImage:
            return true
        case .titleCheckbox:
            return true
        case .checkboxTitle:
            return true
        case .imageTitleSubtitle:
            return false
        case .titleSubtitleImage:
            return false
        case .titleSubtitle:
            return false
        case .title:
            return true
        case .titleSubtitleCheckbox:
            return false
        case .checkboxTitleSubtitle:
            return false
        }
    }
    
    func isCheckboxHiddenFor(itemType: MultipleSelectionListItemType) -> Bool {
        switch itemType {
        case .imageTitle:
            return true
        case .titleImage:
            return true
        case .imageTitleSubtitleCheckbox:
            return false
        case .checkboxTitleSubtitleImage:
            return false
        case .imageTitleCheckbox:
            return false
        case .checkboxTitleImage:
            return false
        case .titleCheckbox:
            return false
        case .checkboxTitle:
            return false
        case .imageTitleSubtitle:
            return true
        case .titleSubtitleImage:
            return true
        case .titleSubtitle:
            return true
        case .title:
            return true
        case .titleSubtitleCheckbox:
            return false
        case .checkboxTitleSubtitle:
            return false
        }
    }
    
    func isImageHiddenFor(itemType: SingleSelectionListItemType) -> Bool {
        switch itemType {
        case .imageTitle:
            return false
        case .titleImage:
            return false
        case .imageTitleSubtitle:
            return false
        case .titleSubtitleImage:
            return false
        case .titleSubtitle:
            return true
        case .title:
            return true
        }
    }
    
    func isSubtitleHiddenFor(itemType: SingleSelectionListItemType) -> Bool {
        switch itemType {
        case .imageTitle:
            return true
        case .titleImage:
            return true
        case .imageTitleSubtitle:
            return false
        case .titleSubtitleImage:
            return false
        case .titleSubtitle:
            return false
        case .title:
            return true
        }
    }
    
    func isCheckboxHiddenFor(itemType: SingleSelectionListItemType) -> Bool {
        return true
    }
    
    
    
    static func isImageHiddenFor(itemType: SingleSelectionListItemType) -> Bool {
        switch itemType {
        case .imageTitle:
            return false
        case .titleImage:
            return false
        case .imageTitleSubtitle:
            return false
        case .titleSubtitleImage:
            return false
        case .titleSubtitle:
            return true
        case .title:
            return true
        }
    }
    
    static func isImageHiddenFor(itemType: TwoColumnSingleSelectionListItemType) -> Bool {
        switch itemType {
        case .tittle, .titleSubtitle:
            
            return true
        default:
            return false
        }
    }
    
    static func isImageHiddenFor(itemType: TwoColumnMultipleSelectionListItemType) -> Bool {
        switch itemType {
        case .tittle, .titleSubtitle:
            
            return true
        default:
            return false
        }
    }
    
}
