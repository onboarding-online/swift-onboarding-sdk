//
//  File.swift
//  
//
//  Created by Leonid Yuriev on 17.03.24.
//

import Foundation
import ScreensGraph

final class PaywallCellWithBorderConfigurator: CellConfigurator {
    var cellLeading: CGFloat = 24
    var cellTrailing: CGFloat = 24
    var cellTop: CGFloat = 24
    var cellBottom: CGFloat = 24
    var labelHorizontalSpacing: CGFloat = 4
    
    func calculateHeightFor(item: ItemTypeSubscription, product: StoreKitProduct?, screenData: ScreenBasicPaywall, containerWidth: CGFloat,  currencyFormat: CurrencyFormatKind?) -> CGFloat {
        ///cell size
        cellTrailing = 16 + (screenData.subscriptions.box.styles.paddingRight ?? 0)
        cellLeading = 16 + (screenData.subscriptions.box.styles.paddingLeft ?? 0)
        cellTop = 16 + (screenData.subscriptions.box.styles.paddingTop ?? 0)
        cellBottom = 16 + (screenData.subscriptions.box.styles.paddingBottom ?? 0)
        
        checkboxSize =  checkBoxSizes(subscriptionItem: item)
        
        let containerWidthWithoutPaddings: CGFloat = containerWidth - cellTrailing - cellLeading
        allItemsHorizontalStackViewSpacing = 0
        
        ///cell content size
        containerLeading = screenData.subscriptions.styles.paddingLeft ?? 16
        containerTrailing = screenData.subscriptions.styles.paddingRight ?? 16
        containerTop = screenData.subscriptions.styles.paddingTop ?? 16
        containerBottom = screenData.subscriptions.styles.paddingBottom ?? 16
        
        /// Add gaps between rows and columns
        labelsVerticalStackViewSpacing = item.styles.columnVerticalPadding ?? 4
        labelHorizontalSpacing = item.styles.columnHorizontalPadding ?? 4
        if item.isOneColumn() {
            labelHorizontalSpacing = 0.0
        }
        
        // Calculate effective width for labels heights calculation
        var labelWidth = containerWidthWithoutPaddings - containerLeading - containerTrailing
        
        if !isImageHiddenFor(item: item) {
            labelWidth -= (imageWidth + allItemsHorizontalStackViewSpacing)
        } else {
            self.imageWidth = 0
            self.imageHeigh = 0
        }
        
        /// Add checkbox width
        if !isCheckboxHiddenFor(list: screenData.subscriptions) {
            let checkBoxContainer = (item.checkBox.styles.width ?? 24.0) + (item.checkBox.box.styles.paddingLeft ?? 0.0) + (item.checkBox.box.styles.paddingRight ?? 0.0)
            labelWidth = labelWidth - checkBoxContainer
        }
        
        //Calculate labels height
        var totalLabelsBlockHeight = 0.0
        var subtitleHeight: CGFloat = 0.0
        
        let titleText: Text
        let subtitleText: Text
        
        ///Calculate size of columns
        let leftColumnSize = (item.styles.leftLabelColumnWidthPercentage ?? 60)/100.00
        let rightColumnSize = 1 - leftColumnSize
        
        var leftColumnSizeValue = (labelWidth) * leftColumnSize
        var rightColumnSizeValue = labelWidth  * rightColumnSize - labelHorizontalSpacing
        
        /// If one column is empty then use all container width
        if item.isLeftColumnEmpty() {
            rightColumnSizeValue = labelWidth
        }
        
        if item.isRightColumnEmpty() {
            leftColumnSizeValue = labelWidth
        }

        ///Left column height
        let leftColumnHeight = item.leftLabelTop.textHeightBy(textWidth: leftColumnSizeValue, product: product, currencyFormat: currencyFormat) +  item.leftLabelBottom.textHeightBy(textWidth: leftColumnSizeValue, product: product, currencyFormat: currencyFormat)
        ///Right column height
        let rightColumnHeight = item.rightLabelTop.textHeightBy(textWidth: rightColumnSizeValue, product: product, currencyFormat: currencyFormat) +  item.rightLabelBottom.textHeightBy(textWidth: rightColumnSizeValue, product: product, currencyFormat: currencyFormat)

        let floatMaxHeightColumnWidth: Double
        if leftColumnHeight >= rightColumnHeight {
            titleText = item.leftLabelTop
            subtitleText  = item.leftLabelBottom
            floatMaxHeightColumnWidth = leftColumnSizeValue
        } else {
            titleText = item.rightLabelTop
            subtitleText  = item.rightLabelBottom
            floatMaxHeightColumnWidth = rightColumnSizeValue
        }

        let titleHeight = titleText.textHeightBy(textWidth: floatMaxHeightColumnWidth, product: product, currencyFormat: currencyFormat)

        totalLabelsBlockHeight += titleHeight > 0.0 ? titleHeight : 0
        
        subtitleHeight = subtitleText.textHeightBy(textWidth: floatMaxHeightColumnWidth, product: product, currencyFormat: currencyFormat)
        totalLabelsBlockHeight += subtitleHeight > 0.0 ? subtitleHeight : 0
                  
        //Add gap between labels if there are 2 labels
        if item.isTwoLabelInAnyColumn() {
            totalLabelsBlockHeight += labelsVerticalStackViewSpacing
        }
        
        //Get max elemets height for cell height
        var maxHeight = totalLabelsBlockHeight > imageHeigh ? totalLabelsBlockHeight : imageHeigh
        
        maxHeight = maxHeight > checkboxSize ? maxHeight : checkboxSize
        
        let cellHeight = maxHeight + containerTop + containerBottom + 12
        
        return cellHeight
    }
    
    
    func checkBoxSizes(subscriptionItem: ItemTypeSubscription) -> CGFloat {
        let height = subscriptionItem.checkBox.styles.height ?? 24
        let top = subscriptionItem.checkBox.box.styles.paddingTop ?? 0
        let bot =  subscriptionItem.checkBox.box.styles.paddingBottom ?? 0
        
        return height + top + bot
    }
    
    func isCheckboxHiddenFor(list: SubscriptionList) -> Bool {
        switch list.itemType {
        case .checkboxLabels, .labelsCheckbox:
            return false
        default:
            return true
        }
    }
    
    func isImageHiddenFor(item: ItemTypeSubscription) -> Bool {
        return true
    }
}
