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
    
    @IBOutlet private weak var checkbox: UIImageView!
    @IBOutlet private weak var checkBoxContainerView: UIView!
    
    @IBOutlet private weak var leftLabelTop: UILabel!
    @IBOutlet private weak var leftLabelBottom: UILabel!
    
    @IBOutlet private weak var rightLabelTop: UILabel!
    @IBOutlet private weak var rightLabelBottom: UILabel!
        
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
    
    @IBOutlet private weak var savedMoneyViewContainer: UIView!
    @IBOutlet private weak var savedMoneyLabel: UILabel!
    @IBOutlet private weak var saveMoneyLeading: NSLayoutConstraint!
    @IBOutlet private weak var saveMoneyTrailing: NSLayoutConstraint!
    @IBOutlet private weak var saveMoneyCentering: NSLayoutConstraint!

    
    private var currentSavedMoneyViewConstraints: [NSLayoutConstraint] = []
    
    private var item: ItemTypeSubscription? = nil
    private var list: SubscriptionList? = nil
    
    var currencyFormatKind: CurrencyFormatKind?

    
    let badgeView = UIView()
    let badgeLabel = UILabel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        clipsToBounds = false
        
        savedMoneyViewContainer.clipsToBounds = true
        
        savedMoneyLabel.translatesAutoresizingMaskIntoConstraints = false
        savedMoneyViewContainer.translatesAutoresizingMaskIntoConstraints = false
    }
}

// MARK: - Open methods
extension PaywallListSubscriptionCell {
    
    func setWith(isSelected: Bool,
                 subscriptionItem: ItemTypeSubscription,
                 listWithStyles: SubscriptionList,
                 product: StoreKitProduct) {
        
        checkbox.apply(checkbox: subscriptionItem.checkBox, isSelected: isSelected)

        self.item = subscriptionItem
        self.list = listWithStyles
        if let settings = subscriptionItem.badge {
            savedMoneyViewContainer.isHidden = false
            savedMoneyLabel.isHidden = false
            updatePosition(settings: settings)
            

        } else {
            savedMoneyViewContainer.isHidden = true
            savedMoneyLabel.isHidden = true
        }
        
        setSelected(isSelected, listWithStyles: listWithStyles)
        
        setupLabels(subscriptionItem: subscriptionItem, product: product)
        setupCheckboxWith(list: listWithStyles)
        
        if let item = item, let list = list {
            self.layoutSubviews()
            setupSizes(subscriptionItem: item, list: list)
        }
    }
    
    func setWith(isSelected: Bool,
                 subscriptionItem: ItemTypeSubscription,
                 listWithStyles: SubscriptionList) {
        
        checkbox.apply(checkbox: subscriptionItem.checkBox, isSelected: isSelected)

        self.item = subscriptionItem
        self.list = listWithStyles
        if let settings = subscriptionItem.badge {
            savedMoneyViewContainer.isHidden = false
            savedMoneyLabel.isHidden = false
            updatePosition(settings: settings)
            

        } else {
            savedMoneyViewContainer.isHidden = true
            savedMoneyLabel.isHidden = true
        }
        
        setSelected(isSelected, listWithStyles: listWithStyles)
        
        setupLabels(subscriptionItem: subscriptionItem)
        setupCheckboxWith(list: listWithStyles)
        
        if let item = item, let list = list {
            self.layoutSubviews()
            setupSizes(subscriptionItem: item, list: list)
        }
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

        leftLabelTop.text =  subscriptionItem.leftLabelTop.textFor(product: product, currencyFormat: currencyFormatKind)
        leftLabelBottom.text = subscriptionItem.leftLabelBottom.textFor(product: product, currencyFormat: currencyFormatKind)
        rightLabelTop.text = subscriptionItem.rightLabelTop.textFor(product: product, currencyFormat: currencyFormatKind)
        rightLabelBottom.text = subscriptionItem.rightLabelBottom.textFor(product: product, currencyFormat: currencyFormatKind)
    }
    
    func setupLabels(subscriptionItem: ItemTypeSubscription) {
        leftLabelTop.apply(text: subscriptionItem.leftLabelTop)
        leftLabelBottom.apply(text: subscriptionItem.leftLabelBottom)
        rightLabelTop.apply(text: subscriptionItem.rightLabelTop)
        rightLabelBottom.apply(text: subscriptionItem.rightLabelBottom)
    }

}

// MARK: - Private methods
private extension PaywallListSubscriptionCell {
    
    func setSelected(_ isSelected: Bool, listWithStyles: SubscriptionList) {
        if isSelected {
            setSelected(selectedBlock: listWithStyles.selectedBlock)
        } else {
            setDefault(style: listWithStyles.styles)
        }
    }
    
    func setDefault(style: SubscriptionListBlock) {
        contentContainerView.layer.borderWidth = style.borderWidth ?? 0
        contentContainerView.layer.borderColor = (style.borderColor?.hexStringToColor ?? .clear).cgColor
        contentContainerView.layer.cornerRadius = style.borderRadius ?? 0
        
        contentContainerView.backgroundColor = style.backgroundColor?.hexStringToColor ?? .clear
        
        contentContainerView.applyFigmaShadow(x: 0, y: 1, blur: 0, spread: 0, color: .black, alpha: 0.05)
    }
    
    func setSelected(selectedBlock: SelectedSubscriptionListItemBlock) {
        contentContainerView.layer.borderWidth = selectedBlock.styles.borderWidth ?? 0
        contentContainerView.layer.borderColor = (selectedBlock.styles.borderColor?.hexStringToColor ?? .clear).cgColor
        contentContainerView.layer.cornerRadius = selectedBlock.styles.borderRadius ?? 0

        contentContainerView.backgroundColor = selectedBlock.styles.backgroundColor?.hexStringToColor ?? .clear

        contentContainerView.applyFigmaShadow(x: 0, y: 20, blur: 40, spread: 0, color: .black, alpha: 0.15)
    }
    
    func updatePosition(settings: Badge) {
            savedMoneyViewContainer.isHidden = false
            
            savedMoneyViewContainer.backgroundColor = settings.styles.backgroundColor?.hexStringToColor ?? UIColor.clear
            
            savedMoneyViewContainer.layer.borderWidth = settings.styles.borderWidth ?? 0
            savedMoneyViewContainer.layer.cornerRadius = settings.styles.borderRadius ?? 0
            savedMoneyViewContainer.layer.borderColor = settings.styles.borderColor?.hexStringToColor.cgColor ?? UIColor.clear.cgColor

            savedMoneyLabel.apply(badge: settings)

            switch settings.styles.position {
            case .topleft:
                saveMoneyLeading?.isActive = true
                saveMoneyTrailing?.isActive = false
                saveMoneyCentering?.isActive = false
            case .topcenter:
                saveMoneyCentering?.isActive = true
                saveMoneyLeading?.isActive = false
                saveMoneyTrailing?.isActive = false
            case .topright:
                saveMoneyTrailing?.isActive = true
                saveMoneyLeading?.isActive = false
                saveMoneyCentering?.isActive = false
            default:
                saveMoneyTrailing?.isActive = true
                saveMoneyLeading?.isActive = false
                saveMoneyCentering?.isActive = false            }
    }
    
}

// MARK: - Open methods
extension PaywallListSubscriptionCell {
    
    func setupSizes(subscriptionItem: ItemTypeSubscription, list: SubscriptionList) {
        setupCheckBoxSizes(subscriptionItem: subscriptionItem)
        
        mainContainerBottomConstraint.constant = list.styles.paddingBottom ?? 16
        mainContainerTopConstraint.constant = list.styles.paddingTop ?? 16
        mainContainerTrailingConstraint.constant = list.styles.paddingRight ?? 16
        mainContainerLeadingConstraint.constant = list.styles.paddingLeft ?? 16

        cellLeadingConstraint.constant = 16 + (list.box.styles.paddingLeft ?? 0)
        cellTrailingConstraint.constant = 16 + (list.box.styles.paddingRight ?? 0)
        
        let horizontalSpacing = subscriptionItem.styles.columnHorizontalPadding ?? 4
        
        let leftColumnSize = ((subscriptionItem.styles.leftLabelColumnWidthPercentage ?? 60)/100.00)
        _ = 1 - leftColumnSize

        leftStack.translatesAutoresizingMaskIntoConstraints = false
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        containerStack.translatesAutoresizingMaskIntoConstraints = false

        leftStack.spacing = subscriptionItem.styles.columnVerticalPadding ?? 4
        rightStack.spacing = subscriptionItem.styles.columnVerticalPadding ?? 4
        
        leftStack.setContentHuggingPriority(UILayoutPriority(250), for: .horizontal) // Для вертикального стека
        leftStack.setContentCompressionResistancePriority(UILayoutPriority(750), for: .horizontal) // Для вертикального стека
        
        rightStack.setContentHuggingPriority(UILayoutPriority(250), for: .horizontal) // Для вертикального стека
        rightStack.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal) // Для вертикального стека

        let labels = [leftLabelTop, leftLabelBottom, rightLabelTop, rightLabelBottom]
        
        for label in labels {
            if let label = label {
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = 0.5
                
                label.setContentHuggingPriority(UILayoutPriority(250), for: .vertical)
                label.setContentCompressionResistancePriority(UILayoutPriority(750), for: .vertical)
  
                label.setContentHuggingPriority(UILayoutPriority(250), for: .horizontal)
                label.setContentCompressionResistancePriority(UILayoutPriority(750), for: .horizontal)
                
                label.numberOfLines = 0
            }
        }
        
        if !subscriptionItem.isOneColumn() {
            containerStack.spacing = horizontalSpacing
            (leftStack.widthAnchor.constraint(equalTo: containerStack.widthAnchor, multiplier: leftColumnSize)).isActive = true
        }
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
