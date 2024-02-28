//
//  PaywallListSubscriptionCell.swift
//  
//
//  Created by Oleg Kuplin on 26.12.2023.
//

import UIKit
import ScreensGraph

final class PaywallListSubscriptionCell: UICollectionViewCell {

    @IBOutlet private weak var contentContainerView: UIView!
    @IBOutlet private weak var mainContainerStack: UIStackView!

    @IBOutlet private weak var checkbox: PaywallCheckboxView!
    @IBOutlet private weak var checkBoxContainerView: UIView!

    @IBOutlet private weak var leftLabelTop: UILabel!
    @IBOutlet private weak var leftLabelBottom: UILabel!
    
    @IBOutlet private weak var rightLabelTop: UILabel!
    @IBOutlet private weak var rightLabelBottom: UILabel!

    @IBOutlet private weak var contentLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var mainContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mainContainerTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mainContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mainContainerBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var cellLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var cellTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var cellTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var cellBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var checkBoxHeight: NSLayoutConstraint!
    @IBOutlet private weak var checkBoxWidth: NSLayoutConstraint!
    
    @IBOutlet private weak var checkBoxLeading: NSLayoutConstraint!
    @IBOutlet private weak var checkBoxTrailing: NSLayoutConstraint!
    @IBOutlet private weak var checkBoxBot: NSLayoutConstraint!
    @IBOutlet private weak var checkBoxTop: NSLayoutConstraint!

    @IBOutlet private weak var containerStack: UIStackView!
    @IBOutlet private weak var leftStack: UIStackView!
    @IBOutlet private weak var rightStack: UIStackView!

    
    @IBOutlet private weak var savedMoneyView: SavedMoneyView!
    private var currentSavedMoneyViewConstraints: [NSLayoutConstraint] = []
    
    private var item: ItemTypeSubscription! = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        
        clipsToBounds = false
        savedMoneyView.translatesAutoresizingMaskIntoConstraints = false
    }

}

// MARK: - Open methods
extension PaywallListSubscriptionCell {
    
    func setWith(configuration: PaywallVC.ListSubscriptionCellConfiguration,
                 isSelected: Bool,
                 subscriptionItem: ItemTypeSubscription,
                 listWithStyles: SubscriptionList,
                 product: StoreKitProduct) {
        if isSelected {
            checkbox.tintColor = subscriptionItem.checkBox.selectedBlock.styles.color?.hexStringToColor
        } else {
            checkbox.tintColor = subscriptionItem.checkBox.selectedBlock.styles.color?.hexStringToColor
        }
        
        self.item = subscriptionItem
        setupSizes(subscriptionItem: subscriptionItem, list: listWithStyles)
        setBadgePosition(configuration.badgePosition, settings: item.badge)
        setSelected(isSelected, listWithStyles: listWithStyles)
        
        setupLabels(subscriptionItem: subscriptionItem, product: product)
        setupCheckboxWith(list: listWithStyles)
    }
    
    func setupCheckboxWith(list: SubscriptionList) {
        switch list.itemType {
        case .checkboxLabels:
            break
        case .labelsCheckbox:
            checkBoxContainerView.removeFromSuperview()
            mainContainerStack.insertArrangedSubview(checkBoxContainerView, at: 1)
        default:
            checkBoxContainerView.isHidden = true
        }
        mainContainerStack.setNeedsLayout()
        mainContainerStack.layoutIfNeeded()
    }
    
    func setupLabels(subscriptionItem: ItemTypeSubscription, product: StoreKitProduct) {
        leftLabelTop.apply(text: subscriptionItem.leftLabelTop)
        leftLabelBottom.apply(text: subscriptionItem.leftLabelBottom)
        rightLabelTop.apply(text: subscriptionItem.rightLabelTop)
        rightLabelBottom.apply(text: subscriptionItem.rightLabelBottom)

        leftLabelTop.text =  subscriptionItem.leftLabelTop.textFor(product: product)
        leftLabelBottom.text = subscriptionItem.leftLabelBottom.textFor(product: product)
        rightLabelTop.text = subscriptionItem.rightLabelTop.textFor(product: product)
        rightLabelBottom.text = subscriptionItem.rightLabelBottom.textFor(product: product)
    }
    
    func setWith(configuration: PaywallVC.ListOneTimePurchaseCellConfiguration,
                 isSelected: Bool) {
        // TODO: - Use different cell
//        setBadgePosition(configuration.badgePosition)
//        setSelected(isSelected)
    }
}

// MARK: - Private methods
private extension PaywallListSubscriptionCell {
    
    func setSelected(_ isSelected: Bool, listWithStyles: SubscriptionList) {
        checkbox.isOn = isSelected
        if isSelected {
            setSelected(selectedBlock: listWithStyles.selectedBlock)
        } else {
            setDefault(style: listWithStyles.styles)
        }
    }
    
    func setDefault(style: SubscriptionListBlock) {
        contentContainerView.layer.borderWidth = style.borderWidth ?? 0
        contentContainerView.layer.borderColor = style.borderColor?.hexStringToColor.cgColor
        contentContainerView.layer.cornerRadius = style.borderRadius ?? 0

        contentContainerView.backgroundColor = style.backgroundColor?.hexStringToColor ?? .black.withAlphaComponent(0.05)
        
        contentContainerView.applyFigmaShadow(x: 0, y: 1, blur: 0, spread: 0, color: .black, alpha: 0.05)
    }
    
    func setSelected(selectedBlock: SelectedSubscriptionListItemBlock) {
        contentContainerView.layer.borderWidth = selectedBlock.styles.borderWidth ?? 0
        contentContainerView.layer.borderColor = selectedBlock.styles.borderColor?.hexStringToColor.cgColor
        contentContainerView.layer.cornerRadius = selectedBlock.styles.borderRadius ?? 0

        contentContainerView.backgroundColor = selectedBlock.styles.backgroundColor?.hexStringToColor ?? .black.withAlphaComponent(0.05)

        contentContainerView.applyFigmaShadow(x: 0, y: 20, blur: 40, spread: 0, color: .black, alpha: 0.15)
    }
    
    func setBadgePosition(_ position: SavedMoneyBadgePosition, settings: Badge?) {
       
        NSLayoutConstraint.deactivate(currentSavedMoneyViewConstraints)

        var constraints: [NSLayoutConstraint] = [savedMoneyView.heightAnchor.constraint(equalToConstant: 24),
                                                 savedMoneyView.centerYAnchor.constraint(equalTo: topAnchor)]
        
        if let badge = settings {
            savedMoneyView.isHidden = false
            
            savedMoneyView.backgroundColor = badge.styles.backgroundColor?.hexStringToColor
            savedMoneyView.layer.borderWidth = badge.styles.borderWidth ?? 0
            savedMoneyView.layer.cornerRadius = badge.styles.borderRadius ?? 0
            savedMoneyView.layer.borderColor = badge.styles.borderColor?.hexStringToColor.cgColor

            savedMoneyView.label.apply(badge: settings)
            switch badge.styles.position {
            case .topleft:
                constraints.append(savedMoneyView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 16))
            case .topcenter:
                constraints.append(savedMoneyView.centerXAnchor.constraint(equalTo: centerXAnchor))
            case .topright:
                constraints.append(contentContainerView.trailingAnchor.constraint(equalTo: savedMoneyView.trailingAnchor, constant: 16))
            default:
                constraints.append(savedMoneyView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 16))
            }
        } else {
            savedMoneyView.isHidden = true
        }
        
        NSLayoutConstraint.activate(constraints)
        currentSavedMoneyViewConstraints = constraints
    }
    
}

// MARK: - Open methods
extension PaywallListSubscriptionCell {
    
    func setupSizes(subscriptionItem: ItemTypeSubscription, list: SubscriptionList) {

        setupCheckBoxSizes(subscriptionItem: subscriptionItem)
        
        mainContainerBottomConstraint.constant = subscriptionItem.box.styles.paddingBottom ?? 16
        mainContainerTopConstraint.constant = subscriptionItem.box.styles.paddingTop ?? 16
        mainContainerTrailingConstraint.constant = subscriptionItem.box.styles.paddingRight ?? 16
        mainContainerLeadingConstraint.constant = subscriptionItem.box.styles.paddingLeft ?? 16

        cellLeadingConstraint.constant = 16 + (list.box.styles.paddingLeft ?? 0)
        cellTrailingConstraint.constant = 16 + (list.box.styles.paddingRight ?? 0)
        
        let leftColumnSize = (subscriptionItem.styles.leftLabelColumnWidthPercentage ?? 60)/100.00
        let rightColumnSize = 1 - leftColumnSize
        
        leftStack.spacing = item.styles.columnVerticalPadding ?? 4
        rightStack.spacing = item.styles.columnVerticalPadding ?? 4
        
        containerStack.spacing = item.styles.columnHorizontalPadding ?? 4

//        let isLeftColumnEmpty = subscriptionItem.leftLabelBottom.textByLocale().isEmpty &&  subscriptionItem.leftLabelTop.textByLocale().isEmpty
//
//        let isRightColumnEmpty = subscriptionItem.rightLabelTop.textByLocale().isEmpty &&  subscriptionItem.rightLabelBottom.textByLocale().isEmpty
//
//        if  isLeftColumnEmpty ||  isRightColumnEmpty{
//
//        } else {
//            leftStack.widthAnchor.constraint(equalTo: containerStack.widthAnchor, multiplier: leftColumnSize).isActive = true
//            rightStack.widthAnchor.constraint(equalTo: containerStack.widthAnchor, multiplier: rightColumnSize).isActive = true
//        }
        
        let widthConstraintLeft = leftStack.widthAnchor.constraint(equalTo: containerStack.widthAnchor, multiplier: leftColumnSize)
        widthConstraintLeft.priority = .defaultHigh
        widthConstraintLeft.isActive = true
        
        let widthConstraintRight = rightStack.widthAnchor.constraint(equalTo: containerStack.widthAnchor, multiplier: rightColumnSize)
        widthConstraintRight.priority = .defaultHigh
        widthConstraintRight.isActive = true
    }
    
    func setupCheckBoxSizes(subscriptionItem: ItemTypeSubscription) {
        checkBoxHeight.constant = subscriptionItem.checkBox.styles.width ?? 24
        checkBoxWidth.constant = subscriptionItem.checkBox.styles.height ?? 24
        checkBoxTrailing.constant = subscriptionItem.checkBox.box.styles.paddingRight ?? 0
        checkBoxLeading.constant = subscriptionItem.checkBox.box.styles.paddingLeft ?? 0
        checkBoxTop.constant = subscriptionItem.checkBox.box.styles.paddingTop ?? 0
        checkBoxBot.constant = subscriptionItem.checkBox.box.styles.paddingBottom ?? 0
    }
    
    enum SavedMoneyBadgePosition {
        case none, left, center, right
    }
}
