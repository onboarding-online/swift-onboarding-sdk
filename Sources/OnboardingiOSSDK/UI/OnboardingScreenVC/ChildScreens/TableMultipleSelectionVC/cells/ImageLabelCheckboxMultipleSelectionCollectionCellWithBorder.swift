//
//  CollectionLabelCell.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 24.05.2023.
//

import UIKit
import ScreensGraph

final class ImageLabelCheckboxMultipleSelectionCollectionCellWithBorderConfigurator: CellConfigurator { }


final class ImageLabelCheckboxMultipleSelectionCollectionCellWithBorder: UICollectionViewCell, UIImageLoader {
    
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
            load(image: item.image, in: cellImage, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
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
fileprivate extension ImageLabelCheckboxMultipleSelectionCollectionCellWithBorder {
    
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

    
    func setupUIBy(type: SingleSelectionListItemType) {
        setupDefaultVisibility()
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
            break
        case .titleSubtitleImage:
            setupImagesInStackView()
        case .titleSubtitle:
            cellImage.isHidden = true
        case .title:
            cellImage.isHidden = true
            subtitleLabel.isHidden = true
        }
    }
    
}

fileprivate extension ImageLabelCheckboxMultipleSelectionCollectionCellWithBorder {
    
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
        allItemsHorizontalStackView.spacing = cellConfig.allItemsHorizontalStackViewSpacing
        labelsVerticalStackView.spacing = cellConfig.labelsVerticalStackViewSpacing
        
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
        titleLabel.isHidden = false
    }
    
}

