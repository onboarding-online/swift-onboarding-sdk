//
//  CollectionLabelCell.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 24.05.2023.
//

import UIKit
import ScreensGraph



final class ImageLabelCheckboxMultipleSelectionCollectionCellWithBorderFlexiblePaddings: UICollectionViewCell, UIImageLoader {
    
    @IBOutlet weak var containerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelContainerView: UIView!
    @IBOutlet weak var titleLabelContainerBoxView: UIView!
    
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var subtitleLabelContainerView: UIView!
    @IBOutlet weak var subtitleLabelContainerBoxView: UIView!


    @IBOutlet weak var labelsVerticalStackView: UIStackView!

    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cellImageWidthConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var titleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var titleBoxLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleBoxTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleBoxTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleBoxBottomConstraint: NSLayoutConstraint!

    
    @IBOutlet weak var subtitleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var subtitleBoxLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleBoxTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleBoxTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleBoxBottomConstraint: NSLayoutConstraint!

    
    @IBOutlet weak var checkbox: UIImageView!
    @IBOutlet weak var checkboxSizeConstraint: NSLayoutConstraint!

    @IBOutlet weak var allItemsHorizontalStackView: UIStackView!
    
    @IBOutlet weak var backgroundContentView: UIView!
    
    var currentItem: ItemTypeSelection?
    
    var cellConfig: ImageLabelCheckboxMultipleSelectionCollectionCellWithBorderConfigurator? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let config = cellConfig {
       
            configDefaultUIConstraintWith(cellConfig: config)
            
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let config = cellConfig {
            configDefaultUIConstraintWith(cellConfig: config)
        }
    }
    
    func setWith(list: MultipleSelectionList, item: ItemTypeSelection, isSelected: Bool,
                 useLocalAssetsIfAvailable: Bool) {
        setupUIBy(type: list.itemType)

        titleLabel.apply(text: item.title)
        subtitleLabel.apply(text: item.subtitle)
        
        titleLabelContainerView.isHidden = item.title.textByLocale().isEmpty
        titleLabelContainerBoxView.isHidden = item.title.textByLocale().isEmpty
        
        if !(cellConfig?.isSubtitleHiddenFor(itemType: list.itemType) ?? true) {
            subtitleLabelContainerView.isHidden =  item.subtitle.textByLocale().isEmpty
            subtitleLabelContainerBoxView.isHidden =  item.subtitle.textByLocale().isEmpty
        }


        if let config = cellConfig, !config.isImageHiddenFor(itemType: list.itemType)  {
            loadImageFor(item: item,
                         useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
        }
        
        checkbox.apply(checkbox: item.checkBox, isSelected: isSelected)

        if isSelected {
            backgroundContentView.apply(listStyle: list.selectedBlock.styles)
        } else {
            backgroundContentView.apply(listStyle: list.styles)
        }

        setupEmptyStateForTitleAndSubtitle()
        
        self.layoutIfNeeded()
    }

    func setWith(list: SingleSelectionList, item: ItemTypeSelection, styles: ListBlock, isSelected: Bool,
                 useLocalAssetsIfAvailable: Bool) {
        setupUIBy(type: list.itemType)

        titleLabel.apply(text: item.title)
        subtitleLabel.apply(text: item.subtitle)
        
        titleLabelContainerView.isHidden = item.title.textByLocale().isEmpty
        titleLabelContainerBoxView.isHidden = item.title.textByLocale().isEmpty
        
        if !(cellConfig?.isSubtitleHiddenFor(itemType: list.itemType) ?? true) {
            subtitleLabelContainerView.isHidden =  item.subtitle.textByLocale().isEmpty
            subtitleLabelContainerBoxView.isHidden = item.subtitle.textByLocale().isEmpty
        }
        
        if !ImageLabelCheckboxMultipleSelectionCollectionCellWithBorderConfigurator.isImageHiddenFor(itemType: list.itemType) {
            loadImageFor(item: item,
                         useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
        }

        checkbox.apply(checkbox: item.checkBox, isSelected: isSelected)

        if isSelected {
            backgroundContentView.apply(listStyle: list.selectedBlock.styles)
        } else {
            backgroundContentView.apply(listStyle: list.styles)
        }
        
        setupEmptyStateForTitleAndSubtitle()
        
        self.layoutIfNeeded()
    }
    
    func setupEmptyStateForTitleAndSubtitle() {
        if (titleLabel.text?.isEmpty ?? true)  && (subtitleLabel.text?.isEmpty ?? true ){
            titleLabel.text = " "
            titleLabel.isHidden = false
        }
    }
    
    func loadImageFor(item: ItemTypeSelection, useLocalAssetsIfAvailable: Bool) {
        if currentItem != item {
            load(
                image: item.image,
                in: cellImage,
                useLocalAssetsIfAvailable: useLocalAssetsIfAvailable,
                animated: false
            )
            currentItem = item
            setupImageContentMode(item: item)
        }
    }
    
    func setupImageContentMode(item: ItemTypeSelection) {
        if let imageContentMode = item.image.imageContentMode() {
            cellImage.contentMode = imageContentMode
        } else {
            cellImage.contentMode = .scaleToFill
        }
    }
    
    
}

// MARK: - Open methods
fileprivate extension ImageLabelCheckboxMultipleSelectionCollectionCellWithBorderFlexiblePaddings {
    
    func setupImagesInStackView() {
        checkbox.removeFromSuperview()
        cellImage.removeFromSuperview()
    
        allItemsHorizontalStackView.insertArrangedSubview(checkbox, at: 0)
        allItemsHorizontalStackView.insertArrangedSubview(cellImage, at: 2)
        
        allItemsHorizontalStackView.setNeedsLayout()
        allItemsHorizontalStackView.layoutIfNeeded()
    }
    
    private func setupImage(item: ItemTypeSelection, useLocalAssetsIfAvailable: Bool) {
        load(image: item.image, in: cellImage, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
    }
 
    func setupUIBy(type: MultipleSelectionListItemType) {
        setupDefaultVisibility()
        switch type {
        case .imageTitleSubtitleCheckbox:
            break
        case .checkboxTitleSubtitleImage:
            setupImagesInStackView()
        case .imageTitleCheckbox:
            subtitleLabel.isHidden = true
            subtitleLabelContainerView.isHidden = true
            subtitleLabelContainerBoxView.isHidden = true
        case .checkboxTitleImage:
            subtitleLabel.isHidden = true
            subtitleLabelContainerView.isHidden = true
            subtitleLabelContainerBoxView.isHidden = true
            setupImagesInStackView()
        case .titleCheckbox:
            subtitleLabel.isHidden = true
            subtitleLabelContainerView.isHidden = true
            subtitleLabelContainerBoxView.isHidden = true

            cellImage.isHidden = true
        case .checkboxTitle:
            subtitleLabel.isHidden = true
            subtitleLabelContainerView.isHidden = true
            subtitleLabelContainerBoxView.isHidden = true

            cellImage.isHidden = true

            setupImagesInStackView()
        case .titleImage:
            subtitleLabel.isHidden = true
            subtitleLabelContainerView.isHidden = true
            subtitleLabelContainerBoxView.isHidden = true

            checkbox.isHidden = true
            setupImagesInStackView()
        case .imageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
            subtitleLabelContainerView.isHidden = true
            subtitleLabelContainerBoxView.isHidden = true

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
            subtitleLabelContainerView.isHidden = true
            subtitleLabelContainerBoxView.isHidden = true

            cellImage.isHidden = true
        case .titleSubtitleCheckbox:
            cellImage.isHidden = true
        case .checkboxTitleSubtitle:
            cellImage.isHidden = true
            setupImagesInStackView()
        }
    }

    
    func setupUIBy(type: SingleSelectionListItemType) {
        setupDefaultVisibility()
        checkbox.isHidden = true

        switch type {
        case .titleImage:
            subtitleLabel.isHidden = true
            subtitleLabelContainerView.isHidden = true
            subtitleLabelContainerBoxView.isHidden = true

            checkbox.isHidden = true
            setupImagesInStackView()
        case .imageTitle:
            checkbox.isHidden = true
            subtitleLabel.isHidden = true
            subtitleLabelContainerView.isHidden = true
            subtitleLabelContainerBoxView.isHidden = true

        case .imageTitleSubtitle:
            break
        case .titleSubtitleImage:
            setupImagesInStackView()
        case .titleSubtitle:
            cellImage.isHidden = true
        case .title:
            cellImage.isHidden = true
            subtitleLabel.isHidden = true
            subtitleLabelContainerView.isHidden = true
            subtitleLabelContainerBoxView.isHidden = true
        }
    }
    
}

fileprivate extension ImageLabelCheckboxMultipleSelectionCollectionCellWithBorderFlexiblePaddings {
    
    func setupUIBy(type: Any) {
        if let type = type as? MultipleSelectionListItemType {
            setupUIBy(type: type)
            return
        }
        
        if let type = type as? SingleSelectionListItemType {
            setupUIBy(type: type)
            return
        }
    }
    
    func configDefaultUIConstraintWith(cellConfig: ImageLabelCheckboxMultipleSelectionCollectionCellWithBorderConfigurator) {
        cellConfig.allItemsHorizontalStackViewSpacing = 0
        
        
        titleLeadingConstraint.constant = (cellConfig.currentItem?.title.box.styles.paddingLeft ?? 0.0).cgFloatValue
        titleTrailingConstraint.constant = (cellConfig.currentItem?.title.box.styles.paddingRight ?? 0.0).cgFloatValue
        titleTrailingConstraint.constant = (cellConfig.currentItem?.title.box.styles.paddingRight ?? 0.0).cgFloatValue
        titleBottomConstraint.constant = (cellConfig.currentItem?.title.box.styles.paddingBottom ?? 0.0).cgFloatValue
        titleTopConstraint.constant = (cellConfig.currentItem?.title.box.styles.paddingTop ?? 0.0).cgFloatValue
        
        subtitleLeadingConstraint.constant = (cellConfig.currentItem?.subtitle.box.styles.paddingLeft ?? 0.0).cgFloatValue
        subtitleTrailingConstraint.constant = (cellConfig.currentItem?.subtitle.box.styles.paddingRight ?? 0.0).cgFloatValue
        subtitleBottomConstraint.constant = (cellConfig.currentItem?.subtitle.box.styles.paddingBottom ?? 0.0).cgFloatValue
        subtitleTopConstraint.constant = (cellConfig.currentItem?.subtitle.box.styles.paddingTop ?? 0.0).cgFloatValue
        
        
        titleBoxLeadingConstraint.constant = (cellConfig.currentItem?.title.styles.paddingLeft ?? 0.0).cgFloatValue
        titleBoxTrailingConstraint.constant = (cellConfig.currentItem?.title.styles.paddingRight ?? 0.0).cgFloatValue
        titleBoxBottomConstraint.constant = (cellConfig.currentItem?.title.styles.paddingBottom ?? 0.0).cgFloatValue
        titleBoxTopConstraint.constant = (cellConfig.currentItem?.title.styles.paddingTop ?? 0.0).cgFloatValue
        
        subtitleBoxLeadingConstraint.constant = (cellConfig.currentItem?.subtitle.styles.paddingLeft ?? 0.0).cgFloatValue
        subtitleBoxTrailingConstraint.constant = (cellConfig.currentItem?.subtitle.styles.paddingRight ?? 0.0).cgFloatValue
        subtitleBoxBottomConstraint.constant = (cellConfig.currentItem?.subtitle.styles.paddingBottom ?? 0.0).cgFloatValue
        subtitleBoxTopConstraint.constant = (cellConfig.currentItem?.subtitle.styles.paddingTop ?? 0.0).cgFloatValue
        
        
        allItemsHorizontalStackView.spacing = 0
        labelsVerticalStackView.spacing = 0
        
        cellImageWidthConstraint.constant = cellConfig.imageWidth
        cellImageHeightConstraint.constant = cellConfig.imageHeigh
        
        checkboxSizeConstraint.constant = cellConfig.checkboxSize
        
        setupBoxConstraint(top: cellConfig.containerTop,
                          bottom: cellConfig.containerBottom,
                          leading: cellConfig.containerLeading,
                          trailing: cellConfig.containerTrailing)
    }
    
    func setupBoxConstraint(top: CGFloat, bottom: CGFloat, leading: CGFloat, trailing: CGFloat) {
        containerTopConstraint.constant = top
        containerBottomConstraint.constant = bottom
        
        containerLeadingConstraint.constant = leading
        containerTrailingConstraint.constant = trailing
    }
    
    func setupDefaultVisibility() {
        subtitleLabel.isHidden = false
        subtitleLabelContainerView.isHidden = false
        subtitleLabelContainerBoxView.isHidden = false
        titleLabel.isHidden = false
    }
    
}

