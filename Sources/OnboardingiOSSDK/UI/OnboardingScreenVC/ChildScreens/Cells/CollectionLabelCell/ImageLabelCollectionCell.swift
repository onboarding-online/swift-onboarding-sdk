//
//  CollectionLabelCell.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 24.05.2023.
//

import UIKit
import ScreensGraph

final class ImageLabelCollectionCell: UICollectionViewCell, UIImageLoader {

    static let contentItemsSpacing: CGFloat = 8
    static let imageSize: CGFloat = 48  
    static let checkboxSize: CGFloat = 16
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellImageSizeConstraint: NSLayoutConstraint!
    @IBOutlet weak var checkbox: UIImageView!
    @IBOutlet weak var checkboxSizeConstraint: NSLayoutConstraint!

    @IBOutlet weak var stackView: UIStackView!

    @IBOutlet weak var backgroundContentView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        stackView.spacing = ImageLabelCollectionCell.contentItemsSpacing
        cellImageSizeConstraint.constant = ImageLabelCollectionCell.imageSize
        checkboxSizeConstraint.constant = ImageLabelCollectionCell.checkboxSize
    }
    
    static func calculateHeightFor(text: Text,
                                   itemType: RegularListItemType,
                                   containerWidth: CGFloat,
                                   horizontalInset: CGFloat) -> CGFloat {
        var labelWidth = containerWidth - (horizontalInset * 2)
        let titleLabelKey = text.textByLocale()
        let font: UIFont = text.textFont()
        let isImageHidden = isImageHiddenFor(itemType: itemType)
        let isCheckboxHidden = isCheckboxHiddenFor(itemType: itemType)
        
        if !isImageHidden {
            labelWidth -= (imageSize + contentItemsSpacing)
        }
        if !isCheckboxHidden {
            labelWidth -= (checkboxSize + contentItemsSpacing)
        }
        
        let labelHeight = titleLabelKey.height(withConstrainedWidth: labelWidth, font: font)
        let verticalSpacing: CGFloat = 8
        let cellHeight = labelHeight + (verticalSpacing * 2)
        return cellHeight
    }
    
    
    static func calculateHeightFor(text: Text,
                                   itemType: MultipleSelectionListItemType,
                                   containerWidth: CGFloat,
                                   horizontalInset: CGFloat) -> CGFloat {
        var labelWidth = containerWidth - (horizontalInset * 2)
        let titleLabelKey = text.textByLocale()
        let font: UIFont = text.textFont()
        let isImageHidden = isImageHiddenFor(itemType: itemType)
        let isCheckboxHidden = isCheckboxHiddenFor(itemType: itemType)
        
        if !isImageHidden {
            labelWidth -= (imageSize + contentItemsSpacing)
        }
        if !isCheckboxHidden {
            labelWidth -= (checkboxSize + contentItemsSpacing)
        }
        
        let labelHeight = titleLabelKey.height(withConstrainedWidth: labelWidth, font: font)
        let verticalSpacing: CGFloat = 8
        let cellHeight = labelHeight + (verticalSpacing * 2)
        return cellHeight
    }
    
    
    
    
    static func isImageHiddenFor(itemType: RegularListItemType) -> Bool {
        switch itemType {
        case .imageTitle:
            return false
        case .titleImage:
            return false
        }
    }
    
    static func isCheckboxHiddenFor(itemType: RegularListItemType) -> Bool {
        switch itemType {
        case .imageTitle:
            return true
        case .titleImage:
            return true
        }
    }
    
    static func isImageHiddenFor(itemType: MultipleSelectionListItemType) -> Bool {
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
    
    static func isCheckboxHiddenFor(itemType: MultipleSelectionListItemType) -> Bool {
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
    
    func setWith(item: ItemTypeSelection, styles: ListBlock, isSelected: Bool,
                 useLocalAssetsIfAvailable: Bool) {
        titleLabel.apply(text: item.title)
        subtitleLabel.apply(text: item.subtitle)
        setupImage(item: item,
                   useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
        
        checkbox.apply(checkbox: item.checkBox, isSelected: isSelected)
        //        let imageName = isSelected ? "Checkbox_circle_on" : "Checkbox_circle_off"

//        image = UIImage(named: imageName)
//        checkbox.tintColor = item.checkBox.styles.color?.hexStringToColor
//
//
//        checkbox.tintColor = .orange

        backgroundContentView.apply(listStyle: styles)
    }
    
    func setWith(item: ItemTypeRegular, styles: ListBlock, isSelected: Bool,
                 useLocalAssetsIfAvailable: Bool) {
        titleLabel.apply(text: item.title)
        setupImage(item: item,
                   useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
        
        checkbox.applyStaticCheckbox(isSelected: isSelected)
        checkbox.tintColor = .orange

        backgroundContentView.apply(listStyle: styles)
    }

}

// MARK: - Open methods
extension ImageLabelCollectionCell {
        
    func setupImagesInStackView() {
        checkbox.removeFromSuperview()
        cellImage.removeFromSuperview()
    
        stackView.insertArrangedSubview(checkbox, at: 0)
        stackView.insertArrangedSubview(cellImage, at: 2)
        
        stackView.setNeedsLayout()
        stackView.layoutIfNeeded()
    }
    
    private func setupImage(item: ItemTypeSelection,
                            useLocalAssetsIfAvailable: Bool) {
        load(image: item.image, in: cellImage,
             useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
    }
    
    private func setupImage(item: ItemTypeRegular,
                            useLocalAssetsIfAvailable: Bool) {
        load(image: item.image, in: cellImage,
             useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
    }
    
    func setupUIBy(type: SingleSelectionListItemType) {
        checkbox.isHidden = true

        switch type {
        case .titleImage:
            subtitleLabel.isHidden = true
            checkbox.isHidden = true
            setupImagesInStackView()
        case .imageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        case .imageTitleSubtitle:
            checkbox.isHidden = true
        case .titleSubtitleImage:
            checkbox.isHidden = true
            setupImagesInStackView()
        case .titleSubtitle:
            cellImage.isHidden = true
        case .title:
            subtitleLabel.isHidden = true
            cellImage.isHidden = true
        }
    }
    
    func setupUIBy(type: MultipleSelectionListItemType) {
        switch type {
        case .imageTitleSubtitleCheckbox:
            break
        case .checkboxTitleSubtitleImage:
            setupImagesInStackView()
        case .imageTitleCheckbox:
            subtitleLabel.isHidden = true
        case .checkboxTitleImage:
            subtitleLabel.isHidden = true
            setupImagesInStackView()
        case .titleCheckbox:
            subtitleLabel.isHidden = true
            cellImage.isHidden = true
        case .checkboxTitle:
            subtitleLabel.isHidden = true
            cellImage.isHidden = true
            setupImagesInStackView()
        case .titleImage:
            subtitleLabel.isHidden = true
            checkbox.isHidden = true
            setupImagesInStackView()
        case .imageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        case .imageTitleSubtitle:
            checkbox.isHidden = true
        case .titleSubtitleImage:
            checkbox.isHidden = true
            setupImagesInStackView()
        case .titleSubtitle:
            checkbox.isHidden = true
            cellImage.isHidden = true
        case .title:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
            cellImage.isHidden = true
        case .titleSubtitleCheckbox:
            cellImage.isHidden = true
        case .checkboxTitleSubtitle:
            cellImage.isHidden = true
            setupImagesInStackView()
        }
    }
    
    
    
    func setupUIBy(type: TwoColumnMultipleSelectionListItemType) {
        switch type {
        case .tittle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
            cellImage.isHidden = true
        case .titleSubtitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = false
            cellImage.isHidden = true
        case .smallImageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        case .mediumImageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        case .fullImage:
            checkbox.isHidden = true
            subtitleLabel.isHidden = false
            titleLabel.isHidden = false

        case .bigImageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        }
    }
    
    func setupUIBy1(type: TwoColumnSingleSelectionListItemType) {
        switch type {
        case .tittle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
            cellImage.isHidden = true
        case .titleSubtitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = false
            cellImage.isHidden = true
        case .smallImageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        case .mediumImageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        case .fullImage:
            checkbox.isHidden = true
            subtitleLabel.isHidden = false
            titleLabel.isHidden = false

        case .bigImageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
        }
        
    }
    
    func setupUIBy(type: RegularListItemType) {
        cellImage.isHidden = ImageLabelCollectionCell.isImageHiddenFor(itemType: type)
        checkbox.isHidden = ImageLabelCollectionCell.isCheckboxHiddenFor(itemType: type)
        subtitleLabel.isHidden = true
    }
    
}
