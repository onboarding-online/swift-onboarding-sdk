//
//  CollectionLabelCell.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 24.05.2023.
//

import UIKit
import ScreensGraph

final class BulletsImageLabelCollectionCell: UICollectionViewCell, UIImageLoader {
    
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
    
    var cellConfig: BulletsImageLabelCollectionCellConfigurator? = nil

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

    func setWith(listType: RegularListItemType, item: ItemTypeRegular, styles: ListBlock, isSelected: Bool,
                 useLocalAssetsIfAvailable: Bool) {
        titleLabel.apply(text: item.title)
        setupImage(item: item, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
        backgroundContentView.apply(listStyle: styles)
        setupUIBy(type: listType)
        
        setupEmptyStateForTitleAndSubtitle()
        
        self.layoutSubviews()
    }
    
}

// MARK: - Open methods
fileprivate extension BulletsImageLabelCollectionCell {
    
    func setupEmptyStateForTitleAndSubtitle() {
        if (titleLabel.text?.isEmpty ?? true) {
            titleLabel.text = " "
            titleLabel.isHidden = false
        }
    }
    
    func setupImagesInStackView() {
        checkbox.removeFromSuperview()
        cellImage.removeFromSuperview()
    
        allItemsHorizontalStackView.insertArrangedSubview(checkbox, at: 0)
        allItemsHorizontalStackView.insertArrangedSubview(cellImage, at: 2)
        
        allItemsHorizontalStackView.setNeedsLayout()
        allItemsHorizontalStackView.layoutIfNeeded()
    }
    
    func setupImage(item: ItemTypeRegular, useLocalAssetsIfAvailable: Bool) {
        load(image: item.image, in: cellImage, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
        setupImageContentMode(item: item)
    }
    
    func setupImageContentMode(item: ItemTypeRegular) {
        if let imageContentMode = item.image.imageContentMode() {
            cellImage.contentMode = imageContentMode
        } else {
            cellImage.contentMode = .scaleAspectFit
        }
    }
}

fileprivate extension BulletsImageLabelCollectionCell {
    
    func setupUIBy(type: RegularListItemType) {
        guard let cellConfig = cellConfig else { return  }
        
        cellImage.isHidden = cellConfig.isImageHiddenFor(itemType: type)
        checkbox.isHidden = cellConfig.isCheckboxHiddenFor(itemType: type)
       
        subtitleLabel.isHidden = true
        
        switch type {
        case .titleImage:
            setupImagesInStackView()
        case .imageTitle:
            break
        }
    }
    
    func configDefaultUIConstraintWith(cellConfig: BulletsImageLabelCollectionCellConfigurator) {
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
    
}

final class BulletsImageLabelCollectionCellConfigurator: CellConfigurator {
    
    override func isImageHiddenFor(itemType: Any?) -> Bool {
        guard let itemType = itemType as? RegularListItemType else { return false }
        
        switch itemType {
        case .imageTitle:
            return false
        case .titleImage:
            return false
        }
    }
    
    override func isCheckboxHiddenFor(itemType: Any?) -> Bool {
        guard let itemType = itemType as? RegularListItemType else { return false }

        switch itemType {
        case .imageTitle:
            return true
        case .titleImage:
            return true
        }
    }
    
    override func isSubtitleHiddenFor(itemType: Any?) -> Bool {
        return true
    }
}
