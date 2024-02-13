//
//  PaywallHeaderCell.swift
//  
//
//  Created by Oleg Kuplin on 26.12.2023.
//

import UIKit
import ScreensGraph

final class PaywallHeaderCell: UICollectionViewCell {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titlesLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var gradientView: GradientView!
    @IBOutlet private weak var contentStackView: UIStackView!
    
    private var screenData: ScreenBasicPaywall! = nil

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        gradientView.gradientColors = [.clear, .white]
        gradientView.gradientDirection = .topToBottom
        clipsToBounds = false
        titlesLeadingConstraint.constant = UIScreen.isIphoneSE1 ? 12 : 24
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
//            titleLabel.text = title
//            titleLabel.textAlignment = .center
//
            let subtitleLabel = buildLabel()
//            subtitleLabel.textColor = .black.withAlphaComponent(0.5)
//            subtitleLabel.textAlignment = .center
//            subtitleLabel.text = subtitle
            titleLabel.apply(text: screenData.title)
            subtitleLabel.apply(text: screenData.subtitle)

            
            contentStackView.addArrangedSubview(titleLabel)
            contentStackView.addArrangedSubview(subtitleLabel)
            gradientView.gradientColors = [.clear, .white]

        case .titleBulletsList(let title, let bulletsList):
            let titleLabel = buildTitleLabel()
            titleLabel.apply(text: screenData.title)
            contentStackView.addArrangedSubview(titleLabel)
            
            var gradientColors: [UIColor] = [.clear]
            
            
            for item in screenData.list.items {
                let label = buildLabel()
//                label.textColor = .black.withAlphaComponent(0.5)
                label.apply(text: item.title)
//                item.image.styles.width
                let checkmark = buildBulletCheckmark(width: item.image.styles.width ?? 24, height: item.image.styles.height ?? 24)
                
                let hStack = UIStackView(arrangedSubviews: [checkmark, label])
                hStack.axis = .horizontal
                hStack.spacing = 20
                
                contentStackView.addArrangedSubview(hStack)
                
                gradientColors.insert(.clear, at: 0)
                gradientColors.append(.white)
            }
            
//            for item in bulletsList {
//                let label = buildLabel()
//                label.textColor = .black.withAlphaComponent(0.5)
//                label.text = item
//
//                let checkmark = buildBulletCheckmark()
//
//                let hStack = UIStackView(arrangedSubviews: [checkmark, label])
//                hStack.axis = .horizontal
//                hStack.spacing = 20
//
//                contentStackView.addArrangedSubview(hStack)
//
//                gradientColors.insert(.clear, at: 0)
//                gradientColors.append(.white)
//            }
            
            gradientView.gradientColors = gradientColors

        }
    }
    
    func buildBulletCheckmark(width: CGFloat, height: CGFloat) -> UIImageView {
        let imageView = UIImageView(image: .checkmark)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .black
        NSLayoutConstraint.activate([imageView.widthAnchor.constraint(equalToConstant: width),
                                     imageView.heightAnchor.constraint(equalToConstant: height)])
        
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
