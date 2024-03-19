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
    
    //    @IBOutlet private weak var savedMoneyView: SavedMoneyView!
    
    var savedMoneyView: SavedMoneyView = SavedMoneyView()
    
    private var currentSavedMoneyViewConstraints: [NSLayoutConstraint] = []
    
    private var item: ItemTypeSubscription? = nil
    private var list: SubscriptionList? = nil
    
    
    let badgeView = UIView()
    let badgeLabel = UILabel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        clipsToBounds = false
        
        //        addSubview(savedMoneyView)
        
//        setupBadgeViewAndLabel()
        
        savedMoneyView.clipsToBounds = true
        NSLayoutConstraint.activate([
            savedMoneyView.label.topAnchor.constraint(equalTo: savedMoneyView.topAnchor, constant: 0),
            savedMoneyView.label.bottomAnchor.constraint(equalTo: savedMoneyView.bottomAnchor, constant: 0),
            savedMoneyView.label.leadingAnchor.constraint(equalTo: savedMoneyView.leadingAnchor, constant: 0),
            savedMoneyView.label.trailingAnchor.constraint(equalTo: savedMoneyView.trailingAnchor, constant: 0),
        ])
        
        savedMoneyView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(savedMoneyView)
    }
    
    
    
    private func setupBadgeViewAndLabel() {
        badgeView.backgroundColor = .red
        badgeView.layer.cornerRadius = 10
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeView)
        badgeView.isHidden = true
        badgeLabel.textColor = .black
        badgeLabel.font = .boldSystemFont(ofSize: 12)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeView.addSubview(badgeLabel)
        
        NSLayoutConstraint.activate([
            badgeLabel.topAnchor.constraint(equalTo: badgeView.topAnchor, constant: 5),
            badgeLabel.bottomAnchor.constraint(equalTo: badgeView.bottomAnchor, constant: -5),
            badgeLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 10),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -10),
        ])
    }
    
    enum BadgePosition {
        case center
        case left
        case right
    }
    
    func configureBadge(with text: String?, isVisible: Bool, position: BadgePosition) {
        badgeLabel.text = text
        badgeView.isHidden = !isVisible
        
        // Удаляем существующие ограничения badgeView
        badgeView.removeConstraints(badgeView.constraints)
        
        // Восстанавливаем общие ограничения
        NSLayoutConstraint.activate([
            badgeView.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            badgeView.heightAnchor.constraint(equalToConstant: 30), // Пример высоты, может быть изменен
        ])
        
        // Устанавливаем ограничения в зависимости от выбранного положения
        switch position {
        case .center:
            NSLayoutConstraint.activate([
                badgeView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
            ])
        case .left:
            NSLayoutConstraint.activate([
                badgeView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16)
            ])
        case .right:
            NSLayoutConstraint.activate([
                badgeView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16)
            ])
        }
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
        setBadgePosition(settings: subscriptionItem.badge)
        setSelected(isSelected, listWithStyles: listWithStyles)
        
        setupLabels(subscriptionItem: subscriptionItem, product: product)
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

        leftLabelTop.text =  subscriptionItem.leftLabelTop.textFor(product: product)
        leftLabelBottom.text = subscriptionItem.leftLabelBottom.textFor(product: product)
        rightLabelTop.text = subscriptionItem.rightLabelTop.textFor(product: product)
        rightLabelBottom.text = subscriptionItem.rightLabelBottom.textFor(product: product)
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
    
    func setBadgePosition(settings: Badge?) {
        if let badge = settings {
            savedMoneyView.removeConstraints(savedMoneyView.constraints)
            
            NSLayoutConstraint.activate([
                savedMoneyView.heightAnchor.constraint(equalToConstant: 24),
                savedMoneyView.topAnchor.constraint(equalTo: self.topAnchor, constant: -12),
                savedMoneyView.label.topAnchor.constraint(equalTo: savedMoneyView.topAnchor, constant: 0),
                savedMoneyView.label.bottomAnchor.constraint(equalTo: savedMoneyView.bottomAnchor, constant: 0),
                savedMoneyView.label.leadingAnchor.constraint(equalTo: savedMoneyView.leadingAnchor, constant: 6),
                savedMoneyView.label.trailingAnchor.constraint(equalTo: savedMoneyView.trailingAnchor, constant: -6),
            ])

            savedMoneyView.isHidden = false
            
            savedMoneyView.backgroundColor = badge.styles.backgroundColor?.hexStringToColor ?? UIColor.clear
            
            savedMoneyView.layer.borderWidth = badge.styles.borderWidth ?? 0
            savedMoneyView.layer.cornerRadius = badge.styles.borderRadius ?? 0
            savedMoneyView.layer.borderColor = badge.styles.borderColor?.hexStringToColor.cgColor ?? UIColor.clear.cgColor

            savedMoneyView.label.apply(badge: settings)
            switch badge.styles.position {
            case .topleft:
                savedMoneyView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 16).isActive = true
            case .topcenter:
                savedMoneyView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            case .topright:
                savedMoneyView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor, constant: -16).isActive = true
            default:
                savedMoneyView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 16).isActive = true
            }
        } else {
            savedMoneyView.isHidden = true
        }
    }
    
    func setBadgePosition1(settings: Badge?) {
        // Удаляем существующие ограничения badgeView
        badgeView.removeConstraints(badgeView.constraints)
        
        // Восстанавливаем общие ограничения
        NSLayoutConstraint.activate([
            badgeView.topAnchor.constraint(equalTo: self.topAnchor, constant: -12),
//            badgeView.centerYAnchor.constraint(equalTo: contentContainerView.topAnchor
            badgeView.heightAnchor.constraint(equalToConstant: 24), // Пример высоты, может быть изменен
        ])
        
        if let badge = settings {
            badgeLabel.apply(badge: badge)

            badgeView.backgroundColor = badge.styles.backgroundColor?.hexStringToColor ?? UIColor.clear

            badgeView.isHidden = false
            switch badge.styles.position {
            case .topleft:
                badgeView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 16).isActive = true
            case .topcenter:
                badgeView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            case .topright:
                badgeView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor, constant: -16).isActive = true
            default:
                badgeView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 16).isActive = true
            }
        } else {
            badgeView.isHidden = true
        }
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
        let rightColumnSize = 1 - leftColumnSize

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
