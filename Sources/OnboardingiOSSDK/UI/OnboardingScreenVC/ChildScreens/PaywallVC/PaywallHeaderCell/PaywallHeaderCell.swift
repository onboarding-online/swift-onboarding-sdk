//
//  PaywallHeaderCell.swift
//  
//
//  Created by Oleg Kuplin on 26.12.2023.
//

import UIKit
import ScreensGraph

final class PaywallHeaderCell: UICollectionViewCell, UIImageLoader {

    @IBOutlet private weak var imageViewContainer: UIView!
    @IBOutlet private weak var imageViewContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageViewContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageViewContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageViewContainerTrailingConstraint: NSLayoutConstraint!

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

    @IBOutlet private weak var gradientHeightConstraint: NSLayoutConstraint!

    private var videoBackground: VideoBackground?

    @IBOutlet private weak var listBackground: UIView!

    @IBOutlet weak var blurView: UIVisualEffectView!
    
    private var screenData: ScreenBasicPaywall! = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        clipsToBounds = false
        imageViewContainer.bringSubviewToFront(gradientView)
        self.sendSubviewToBack(imageViewContainer)
    }

}

// MARK: - Open methods
extension PaywallHeaderCell {
    
    func imageHeaderSetup() {
        var bottomPadding = screenData.image?.box.styles.paddingBottom ?? 0

        if let verticalPosition = screenData.styles.imageVerticalPosition {
            if verticalPosition == .headerTop {
                imageViewContainer.bottomAnchor.constraint(equalTo: listBackground.topAnchor, constant: bottomPadding).isActive = true
            } else {
                bottomPadding *= -1
                imageViewContainer.bottomAnchor.constraint(equalTo: listBackground.bottomAnchor, constant: bottomPadding).isActive = true
            }
        } else {
            bottomPadding *= -1
            imageViewContainer.bottomAnchor.constraint(equalTo: listBackground.bottomAnchor, constant: bottomPadding).isActive = true
        }
        
        if let box = screenData.image?.box {
            imageViewContainerTopConstraint.constant = box.styles.paddingTop ?? 0
            imageViewContainerTrailingConstraint.constant = box.styles.paddingRight ?? 0
            imageViewContainerLeadingConstraint.constant = box.styles.paddingLeft ?? 0
        }
            
        if let imageContentMode = screenData.image?.imageContentMode() {
            imageView.contentMode = imageContentMode
        } else {
            imageView.contentMode = .scaleAspectFit
        }
    }
    
    func setWith(configuration: PaywallVC.HeaderCellConfiguration) {
        setWithStyle(configuration.style)
        load(image: screenData.image, in: imageView)
    }
    
    func setWith(configuration: PaywallVC.HeaderCellConfiguration, paywallData: ScreenBasicPaywall) {
        screenData = paywallData
        setWithStyle(configuration.style)
        imageHeaderSetup()
        
        load(image: screenData.image, in: imageView)
    }
    
    func setupBackgroundFor(screenId: String,
                            using preparationService: VideoPreparationService) {
        preparationService.observeScreenId(screenId) { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .undefined, .preparing:
                    return
                case .failed:
                    break
                case .ready(let preparedData):
                    self?.playVideoBackgroundWith(preparedData: preparedData)
                }
            }
        }
    }
    

    func playVideoBackgroundWith(preparedData: VideoBackgroundPreparedData) {
        let videoBackgroundHandler: VideoBackground
        if let videoBackground = self.videoBackground {
            videoBackgroundHandler = videoBackground
        } else {
            videoBackgroundHandler = VideoBackground()
            self.videoBackground = videoBackgroundHandler
        }
        
        videoBackgroundHandler.play(in: self.imageViewContainer,
                                    using: preparedData)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            UIView.animate(withDuration: 0.5) {
//                self.backgroundImageView?.alpha = 0
//            } completion: { _ in
//                self.backgroundImageView?.removeFromSuperview()
//                self.backgroundImageView?.alpha = 1
//            }
//        }
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
//            gradientView.gradientColors = [.clear, .white]

        case .titleBulletsList(let title, let bulletsList):
            let titleLabel = buildTitleLabel()
            let subtitleLabel = buildLabel()

            titleLabel.apply(text: screenData.title)
            subtitleLabel.apply(text: screenData.subtitle)

            contentStackView.addArrangedSubview(titleLabel)
            contentStackView.addArrangedSubview(subtitleLabel)

            applyListSettings()
            
            for item in screenData.list.items {
                let label = buildLabel()
                label.apply(text: item.title)
                let checkmark = buildBulletCheckmark(image: item.image)
                
                let hStack = UIStackView(arrangedSubviews: [checkmark, label])
                hStack.axis = .horizontal
                hStack.spacing = 16
                
                contentStackView.addArrangedSubview(hStack)
            }
        }
        setupGradient()
    }
    
    func applyListSettings() {
        blurView.isHidden = true

        if let colorText = screenData.list.styles.backgroundColor {
//            if colorText == "#ffffff" {
//                blurView.isHidden = false
//            } else {
                contentStackView.backgroundColor = colorText.hexStringToColor
                blurView.isHidden = true
//            }
        } else {
            contentStackView.backgroundColor = .clear
        }
        
        listBackground.layer.cornerRadius = screenData.list.styles.borderRadius ?? 0
        listBackground.layer.borderColor = (screenData.list.styles.borderColor?.hexStringToColor ?? .clear).cgColor
        listBackground.layer.borderWidth = screenData.list.styles.borderWidth ?? 0
        
        listLeadingConstraint.constant = screenData.list.box.styles.paddingLeft ?? 24
        listTrailingConstraint.constant = screenData.list.box.styles.paddingRight ?? 24
        listBottomConstraint.constant = screenData.list.box.styles.paddingBottom ?? 24
//
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
        NSLayoutConstraint.activate([imageView.widthAnchor.constraint(equalToConstant: width),
                                     imageView.heightAnchor.constraint(equalToConstant: height)])
        
        applyScaleModeAndLoad(image: image, in: imageView)
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
    
    func setupGradient() {
        if let gradient = screenData.styles.bodyStyle {
            switch gradient {
            case .typeGradient(let gradient):
                if var height = gradient.heightPercentage {
                    height = height / 100
                    gradientView.heightAnchor.constraint(equalTo: imageView.heightAnchor, multiplier:  height).isActive = true
                } else {
                    gradientView.isHidden = true
                }
                if let color = gradient.colors.first?.hexStringToColor {
                    gradientView.gradientColors = [color, .init(white: 1, alpha: 0.001)]
                    gradientView.gradientDirection = .bottomToTop
                }
               
            default:
                gradientView.heightAnchor.constraint(equalTo: imageView.heightAnchor, multiplier:  0.5).isActive = true

                gradientView.gradientColors = [.white, .init(white: 1, alpha: 0.001)]
                gradientView.gradientDirection = .topToBottom
                gradientView.isHidden = true
            }
        } else {
            gradientView.isHidden = true
        }
    
        gradientView.gradientDirection = .bottomToTop
    }
}

// MARK: - Open methods
extension PaywallHeaderCell {
    enum Style {
        case titleSubtitle(title: String, subtitle: String)
        case titleBulletsList(title: String, bulletsList: [String])
    }
}
