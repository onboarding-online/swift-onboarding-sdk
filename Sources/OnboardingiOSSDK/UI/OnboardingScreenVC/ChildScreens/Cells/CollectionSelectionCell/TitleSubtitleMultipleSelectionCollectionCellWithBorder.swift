//
//  CollectionLabelCell.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 24.05.2023.
//

import UIKit
import ScreensGraph

final class TitleSubtitleMultipleSelectionCollectionCellWithBorder: UICollectionViewCell, UIImageLoader {
    
    @IBOutlet weak var containerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var labelsVerticalStackView: UIStackView!

    @IBOutlet weak var allItemsHorizontalStackView: UIStackView!
    
    @IBOutlet weak var backgroundContentView: UIView!
    
    var cellConfig: TextCollectionCellWithBorderConfigurator? = nil

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
    
    
    func setWith(list: TwoColumnSingleSelectionList, item: ItemTypeSelection, isSelected: Bool) {
        setupDefaultVisibility()
        
        titleLabel.apply(text: item.title)
        subtitleLabel.apply(text: item.subtitle)
        if isSelected {
            backgroundContentView.apply(listStyle: list.selectedBlock.styles)
        } else {
            backgroundContentView.apply(listStyle: list.styles)
        }
        setupEmptyStateForTitleAndSubtitle()
    }
    
    func setWith(list: TwoColumnMultipleSelectionList, item: ItemTypeSelection, isSelected: Bool) {
        setupDefaultVisibility()

        titleLabel.apply(text: item.title)
        subtitleLabel.apply(text: item.subtitle)
        if isSelected {
            backgroundContentView.apply(listStyle: list.selectedBlock.styles)
        } else {
            backgroundContentView.apply(listStyle: list.styles)
        }
        setupEmptyStateForTitleAndSubtitle()
    }
    
    func setupEmptyStateForTitleAndSubtitle() {
        if (titleLabel.text?.isEmpty ?? true)  && (subtitleLabel.text?.isEmpty ?? true ){
            titleLabel.text = " "
            titleLabel.isHidden = false
        }
    }
    
}

// MARK: - Open methods
fileprivate extension TitleSubtitleMultipleSelectionCollectionCellWithBorder {
    
    private func setupImage(item: ItemTypeSelection) {
//        load(image: item.image, in: cellImage)
    }
    
}

fileprivate extension TitleSubtitleMultipleSelectionCollectionCellWithBorder {
    
    func configDefaultUIConstraintWith(cellConfig: TextCollectionCellWithBorderConfigurator) {
        allItemsHorizontalStackView.spacing = cellConfig.allItemsHorizontalStackViewSpacing
        labelsVerticalStackView.spacing = cellConfig.labelsVerticalStackViewSpacing
        
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

