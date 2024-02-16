//
//  PaywallHeaderCell.swift
//  
//
//  Created by Oleg Kuplin on 26.12.2023.
//

import UIKit
import ScreensGraph

final class PaywallHeaderCell: UICollectionViewCell, UIImageLoader {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titlesLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var gradientView: GradientView!
    @IBOutlet private weak var contentStackView: UIStackView!
    
    @IBOutlet private weak var listLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var listTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var listBottomConstraint: NSLayoutConstraint!
    
    
    @IBOutlet private weak var listItemLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var listItemTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var listItemTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var listItemBottomConstraint: NSLayoutConstraint!

    
    @IBOutlet private weak var listBackground: UIView!

    @IBOutlet weak var blurView: UIVisualEffectView!
    
    private var screenData: ScreenBasicPaywall! = nil

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        gradientView.gradientColors = [.clear, .white]
        gradientView.gradientDirection = .topToBottom
        clipsToBounds = false
//        titlesLeadingConstraint.constant = UIScreen.isIphoneSE1 ? 12 : 24
    }

}

// MARK: - Open methods
extension PaywallHeaderCell {
    
    func setWith(configuration: PaywallVC.HeaderCellConfiguration) {
        setWithStyle(configuration.style)
        Task { @MainActor in
            imageView.image = await AssetsLoadingService.shared.loadImage(from: configuration.imageURL.absoluteString)
        }
    }
    
    func setWith(configuration: PaywallVC.HeaderCellConfiguration, paywallData: ScreenBasicPaywall) {
        screenData = paywallData
        setWithStyle(configuration.style)
        Task { @MainActor in
                imageView.image = await screenData.image?.loadImage()
        }
    }
    
    func setScrollOffset(_ offset: CGPoint) {
        let offset = min(0, offset.y)
        imageViewTopConstraint.constant = offset
    }
}

// MARK: - Private methods
private extension PaywallHeaderCell {
    
    func setWithStyle(_ style: Style) {
        contentStackView.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        
        switch style {
        case .titleSubtitle(let title, let subtitle):
            let titleLabel = buildTitleLabel()
            let subtitleLabel = buildLabel()

            titleLabel.apply(text: screenData.title)
            subtitleLabel.apply(text: screenData.subtitle)

            contentStackView.addArrangedSubview(titleLabel)
            contentStackView.addArrangedSubview(subtitleLabel)
            gradientView.gradientColors = [.clear, .white]

        case .titleBulletsList(let title, let bulletsList):
            let titleLabel = buildTitleLabel()
            let subtitleLabel = buildLabel()

            titleLabel.apply(text: screenData.title)
            subtitleLabel.apply(text: screenData.subtitle)

            contentStackView.addArrangedSubview(titleLabel)
            contentStackView.addArrangedSubview(subtitleLabel)

//            var gradientColors: [UIColor] = [.clear, .white]
            var gradientColors: [UIColor] = [.clear]

            applyListSettings()
            
            for item in screenData.list.items {
                let label = buildLabel()
                label.apply(text: item.title)
                let checkmark = buildBulletCheckmark(image: item.image)
                
                let hStack = UIStackView(arrangedSubviews: [checkmark, label])
                hStack.axis = .horizontal
                hStack.spacing = 16
                
                contentStackView.addArrangedSubview(hStack)
                
//                gradientColors.insert(.clear, at: 0)
//                gradientColors.append(.white)
            }
                        
            gradientView.gradientColors = gradientColors
        }
    }
    
    func applyListSettings() {
        blurView.isHidden = true

        if let colorText = screenData.list.styles.backgroundColor {
            if colorText == "#ffffff" {
                blurView.isHidden = false
            } else {
                contentStackView.backgroundColor = colorText.hexStringToColor
                blurView.isHidden = true
            }
        } else {
            contentStackView.backgroundColor = .clear
        }
        
        listBackground.layer.cornerRadius = screenData.list.styles.borderRadius ?? 0
        listBackground.layer.borderColor = screenData.list.styles.borderColor?.hexStringToColor.cgColor
        listBackground.layer.borderWidth = screenData.list.styles.borderWidth ?? 0
        
        listLeadingConstraint.constant = screenData.list.box.styles.paddingLeft ?? 24
        listTrailingConstraint.constant = screenData.list.box.styles.paddingRight ?? 24
        listBottomConstraint.constant = screenData.list.box.styles.paddingBottom ?? 24
        
        
//        screenData.list.items.first?.box.styles.paddingBottom
//        screenData.list.styles.paddingLeft
        
        listItemLeadingConstraint.constant = screenData.list.styles.paddingLeft ?? 4
        listItemTrailingConstraint.constant = screenData.list.styles.paddingRight ?? 4
        listItemTopConstraint.constant = screenData.list.styles.paddingTop ?? 8
        listItemBottomConstraint.constant = screenData.list.styles.paddingBottom ?? 8
    }
    
    func buildBulletCheckmark(image: Image) -> UIImageView {
        let width = image.styles.width ?? 24
        let height = image.styles.height ?? 24
       
        let imageView = UIImageView(image: .checkmark)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .black
        NSLayoutConstraint.activate([imageView.widthAnchor.constraint(equalToConstant: width),
                                     imageView.heightAnchor.constraint(equalToConstant: height)])
        
        load(image: image, in: imageView)
        return imageView
    }
    
    func buildTitleLabel() -> UILabel {
        let titleLabel = buildLabel()
        titleLabel.font = .systemFont(ofSize: 23, weight: .bold)
        return titleLabel
    }
    
    func buildLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0

        return label
    }
}

// MARK: - Open methods
extension PaywallHeaderCell {
    enum Style {
        case titleSubtitle(title: String, subtitle: String)
        case titleBulletsList(title: String, bulletsList: [String])
    }
}
