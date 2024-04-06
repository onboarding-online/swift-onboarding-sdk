//
//  CollectionLabelCell.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 24.05.2023.
//

import UIKit
import ScreensGraph

final class ImageLabelCheckboxMultipleSelectionCollectionCellNoBorder: UICollectionViewCell, UIImageLoader {
    
    @IBOutlet weak var containerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var labelsVerticalStackView: UIStackView!

    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cellImageWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var checkbox: UIImageView!
    @IBOutlet weak var checkboxHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var checkboxWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var allItemsHorizontalStackView: UIStackView!
    
    @IBOutlet weak var backgroundContentView: UIView!
    
    var cellConfig: ImageLabelCheckboxMultipleSelectionCollectionCellNoBorderConfigurator? = nil
    
    var currentItem: ItemTypeSelection?


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

        if !(cellConfig?.isImageHiddenFor(itemType: list.itemType) ?? true) {
            setupImageContentMode(item: item)
            loadImageFor(item: item, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
        } else {
            cellImageWidthConstraint.constant = 0
            cellImageHeightConstraint.constant = 0
            self.layoutIfNeeded()
        }

        titleLabel.apply(text: item.title)
        subtitleLabel.apply(text: item.subtitle)

        checkbox.apply(checkbox: item.checkBox, isSelected: isSelected)

        if isSelected {
            backgroundContentView.apply(listStyle: list.selectedBlock.styles)
        } else {
            backgroundContentView.apply(listStyle: list.styles)
        }

        setupEmptyStateForTitleAndSubtitle()
        self.layoutIfNeeded()
    }
    
    func loadImageFor(item: ItemTypeSelection, useLocalAssetsIfAvailable: Bool) {
        if currentItem != item {
            setupImageContentMode(item: item)
            load(image: item.image, in: cellImage, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
            currentItem = item
        }
    }
    
    func setupImageContentMode(item: ItemTypeSelection) {
        if let imageContentMode = item.image.imageContentMode() {
            cellImage.contentMode = imageContentMode
        } else {
            cellImage.contentMode = .scaleAspectFit
        }
    }
    
    func setupEmptyStateForTitleAndSubtitle() {
        if (titleLabel.text?.isEmpty ?? true)  && (subtitleLabel.text?.isEmpty ?? true ){
            titleLabel.text = " "
            titleLabel.isHidden = false
        }
    }
    
}

// MARK: - Open methods
fileprivate extension ImageLabelCheckboxMultipleSelectionCollectionCellNoBorder {
    
    func setupImagesInStackView() {
        checkbox.removeFromSuperview()
        cellImage.removeFromSuperview()
    
        allItemsHorizontalStackView.insertArrangedSubview(checkbox, at: 0)
        allItemsHorizontalStackView.insertArrangedSubview(cellImage, at: 2)
        
        allItemsHorizontalStackView.setNeedsLayout()
        allItemsHorizontalStackView.layoutIfNeeded()
    }
    
    private func setupImage(item: ItemTypeSelection,
                            useLocalAssetsIfAvailable: Bool) {
        load(image: item.image, in: cellImage, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
    }
}

fileprivate extension ImageLabelCheckboxMultipleSelectionCollectionCellNoBorder {
    
    func setupUIBy(type: MultipleSelectionListItemType) {
        setupDefaultVisibility()

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
    
    func configDefaultUIConstraintWith(cellConfig: ImageLabelCheckboxMultipleSelectionCollectionCellNoBorderConfigurator) {
        allItemsHorizontalStackView.spacing = cellConfig.allItemsHorizontalStackViewSpacing
        labelsVerticalStackView.spacing = cellConfig.labelsVerticalStackViewSpacing
        
        cellImageWidthConstraint.constant = cellConfig.imageWidth
        cellImageHeightConstraint.constant = cellConfig.imageHeigh
                
        checkboxHeightConstraint.constant = cellConfig.checkboxSize
        checkboxWidthConstraint.constant = cellConfig.checkboxSize
        
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
        titleLabel.isHidden = false
    }
    
}


final class ImageLabelCheckboxMultipleSelectionCollectionCellNoBorderConfigurator: CellConfigurator {
    
    override func isImageHiddenFor(itemType: Any?) -> Bool {
    
        guard let itemType = itemType as? MultipleSelectionListItemType else { return true }
        
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
    
    override func isCheckboxHiddenFor(itemType: Any?) -> Bool {
        guard let itemType = itemType as? MultipleSelectionListItemType else { return false }

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
}
