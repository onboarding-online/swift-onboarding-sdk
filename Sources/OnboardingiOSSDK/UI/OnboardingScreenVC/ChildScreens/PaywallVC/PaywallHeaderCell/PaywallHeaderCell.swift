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
    
    @IBOutlet private weak var mediaContainer: UIView!

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

    private var videoBackground: VideoBackground? = nil

    @IBOutlet private weak var listBackground: UIView!
    
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
    
    
    func setWith(paywallData: ScreenBasicPaywall) {
//        DispatchQueue.main.async {[weak self]  in
            screenData = paywallData
            setWithStyle()
            imageHeaderSetup()
            if screenData.media?.kind == .image {
                load(image: screenData.image(), in: imageView, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
            }
//        }
    }
    
    func imageHeaderSetup() {
        var bottomPadding = screenData.media?.box.styles.paddingBottom ?? 0


        if let verticalPosition = screenData.styles.imageVerticalPosition {
            if verticalPosition == .headerTop {
                bottomPadding *= -1

                mediaContainer.bottomAnchor.constraint(equalTo: listBackground.topAnchor, constant: bottomPadding).isActive = true
            } else {
                bottomPadding *= -1

                mediaContainer.bottomAnchor.constraint(equalTo: listBackground.bottomAnchor, constant: bottomPadding).isActive = true
            }
        } else {
            bottomPadding *= -1

            mediaContainer.bottomAnchor.constraint(equalTo: listBackground.bottomAnchor, constant: bottomPadding).isActive = true
        }
        
        mediaContainer.layer.cornerRadius = screenData.media?.styles.mainCornerRadius?.cgFloatValue ?? 0
        
        if let box = screenData.media?.box {
            imageViewContainerTopConstraint.constant = box.styles.paddingTop ?? 0
            imageViewContainerTrailingConstraint.constant = box.styles.paddingRight ?? 0
            imageViewContainerLeadingConstraint.constant = box.styles.paddingLeft ?? 0
//            imageViewContainerBottomConstraint.constant = box.styles.paddingBottom ?? 0
        }
            
        if let imageContentMode = screenData.media?.styles.scaleMode?.imageContentMode() {
            imageView.contentMode = imageContentMode
        } else {
            imageView.contentMode = .scaleAspectFit
        }
    }
    
    func setupBackgroundFor(screenId: String,
                            using preparationService: VideoPreparationService) {
        if let status = preparationService.getStatusFor(screenId: screenId),
           case .ready(let preparedData) = status {
            playVideoBackgroundWith(preparedData: preparedData)
        } else {
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
    }
    
    func playVideoBackgroundWith(preparedData: VideoBackgroundPreparedData) {
        if self.videoBackground == nil {
            self.videoBackground = VideoBackground()
            if let mode = screenData.media?.styles.scaleMode?.videoContentMode() {
                videoBackground?.videoGravity = mode
            }
            self.videoBackground!.play(in: self.mediaContainer,
                                        using: preparedData)
        }
    }
    
    func setScrollOffset(_ offset: CGPoint) {
        let offset = min(0, offset.y)
        imageViewTopConstraint.constant = offset
    }
}

// MARK: - Private methods
private extension PaywallHeaderCell {
    var useLocalAssetsIfAvailable: Bool { screenData?.useLocalAssetsIfAvailable ?? true }
    
    func setWithStyle() {
        contentStackView.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        
        if screenData.list.items.count == 1 {
            contentStackView.distribution = .fillProportionally
        } else {
            contentStackView.distribution = .fill
        }
        
        let titleLabel = buildLabel()
        let subtitleLabel = buildLabel()
       
        titleLabel.apply(text: screenData.title)
        subtitleLabel.apply(text: screenData.subtitle)
        
        let titleLabelView = wrapLabelInUIView(label: titleLabel, padding: screenData.title.box.styles)
        let subtitleLabelView = wrapLabelInUIView(label: subtitleLabel, padding: screenData.subtitle.box.styles)
        
       

        if !screenData.title.textByLocale().isEmpty {
            contentStackView.addArrangedSubview(titleLabelView)
        }
        
        if !screenData.subtitle.textByLocale().isEmpty {
            contentStackView.addArrangedSubview(subtitleLabelView)
        }
        
        applyListSettings()
        
        if !screenData.list.items.isEmpty {
            let bulletStackView = UIStackView()
            bulletStackView.translatesAutoresizingMaskIntoConstraints = false
            bulletStackView.axis = .vertical
            bulletStackView.distribution = .fillProportionally
            bulletStackView.alignment = .fill
            if let spacing = screenData.list.styles.itemsSpacing {
                if spacing == 0 {
                    bulletStackView.spacing = 1
                } else {
                    bulletStackView.spacing = spacing
                }
            } else {
                bulletStackView.spacing = screenData.list.styles.itemsSpacing ?? 8
            }
            
            for item in screenData.list.items {
                let title = buildLabel()
                title.apply(text: item.title)
                let subTitle = buildLabel()
                subTitle.apply(text: item.subtitle)
                                

                let checkmark = buildBulletCheckmark(image: item.image)
                
                let vStack = UIStackView.init()

                vStack.translatesAutoresizingMaskIntoConstraints = false
                vStack.distribution = .fill
                vStack.alignment = .fill
                vStack.axis = .vertical
                vStack.spacing = 4
                
                DispatchQueue.main.async {
//                    vStack.addArrangedSubview(titleView)
//                    vStack.addArrangedSubview(subTitleView)
                    vStack.addArrangedSubview(title)
                    vStack.addArrangedSubview(subTitle)
                }
                
                checkmark.setContentCompressionResistancePriority(UILayoutPriority(300), for: .horizontal) // Для вертикального стека
                let hStack = UIStackView(arrangedSubviews: [checkmark, vStack])
                hStack.translatesAutoresizingMaskIntoConstraints = false
                hStack.distribution = .fill
                hStack.alignment = .center
                hStack.axis = .horizontal
                hStack.spacing = 0
                DispatchQueue.main.async {
                    if let width = item.image.styles.width, let height = item.image.styles.width, width == 0,  height == 0 {
                        hStack.spacing = 1
                    } else {
                        hStack.spacing = 16
                    }
                }
                
//                hStack.setContentHuggingPriority(UILayoutPriority(300), for: .horizontal) // Для вертикального стека
//                hStack.setContentCompressionResistancePriority(UILayoutPriority(800), for: .horizontal) // Для вертикального стека

                bulletStackView.addArrangedSubview(hStack)
            }
            contentStackView.translatesAutoresizingMaskIntoConstraints = false
            contentStackView.addArrangedSubview(bulletStackView)
        }
       
        setupGradient()
    }
    
    func wrapLabelInUIView(label: UILabel, padding: BoxBlock? = nil) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        containerView.addSubview(label)
        
        if let padding = padding {
            let bottom = -1 * (padding.paddingBottom ?? 0)
            let trailing = -1 * (padding.paddingRight ?? 0)

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding.paddingTop ?? 0),
                label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottom),
                label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding.paddingLeft ?? 0),
                label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailing)
            ])
        } else {
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
                label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0),
                label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
                label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0)
            ])
        }
        
        return containerView
    }
    
    func applyListSettings() {
        listBackground.layer.cornerRadius = screenData.list.styles.borderRadius ?? 0
        listBackground.layer.borderColor = (screenData.list.styles.borderColor?.hexStringToColor ?? .clear).cgColor
        listBackground.layer.borderWidth = screenData.list.styles.borderWidth ?? 0
        
        listBackground.backgroundColor =   screenData.list.styles.backgroundColor?.hexStringToColor ?? .clear
        listLeadingConstraint.constant = 16.0 + (screenData.list.box.styles.paddingLeft ?? 24)
        listTrailingConstraint.constant =  16.0 + (screenData.list.box.styles.paddingRight ?? 24)
        listBottomConstraint.constant = screenData.list.box.styles.paddingBottom ?? 24
//
        listItemLeadingConstraint.constant = screenData.list.styles.paddingLeft ?? 4
        listItemTrailingConstraint.constant = screenData.list.styles.paddingRight ?? 4
        listItemTopConstraint.constant = screenData.list.styles.paddingTop ?? 8
        listItemBottomConstraint.constant = screenData.list.styles.paddingBottom ?? 8
    }
    
    func buildBulletCheckmark(image: Image) -> UIImageView {
        var width = image.styles.width ?? 1
        var height = image.styles.height ?? 1
       
        width = width == 0 ? 1 : width
        height = height == 0 ? 1 : height

        let imageView = UIImageView.init()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        
        let heightConstraint = imageView.heightAnchor.constraint(equalToConstant: height)
        let widthConstraint = imageView.widthAnchor.constraint(equalToConstant: width)
        widthConstraint.priority = UILayoutPriority(rawValue: 1000)
        
        NSLayoutConstraint.activate([widthConstraint,
                                     heightConstraint])
        
        applyScaleModeAndLoad(image: image, in: imageView, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
        return imageView
    }
    
    func buildTitleLabel() -> UILabel {
        let titleLabel = buildLabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 23, weight: .bold)
        titleLabel.numberOfLines = 0
        return titleLabel
    }
    
    func buildLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        
//        label.adjustsFontSizeToFitWidth = true
//        label.minimumScaleFactor = 0.5

        label.setContentHuggingPriority(UILayoutPriority(300), for: .horizontal) // Для вертикального стека
        label.setContentCompressionResistancePriority(UILayoutPriority(800), for: .horizontal) // Для вертикального стека
//        
        label.setContentHuggingPriority(UILayoutPriority(1000), for: .vertical) // Для вертикального стека
        label.setContentCompressionResistancePriority(UILayoutPriority(800), for: .vertical) // Для вертикального стека
        
        return label
    }
    
    func buildTitleLabelView() -> UIView {
        let titleLabel = buildLabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 23, weight: .bold)
        titleLabel.numberOfLines = 0
        return titleLabel
    }
    
    func buildLabelView() -> UIView
    {
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
                    gradientView.heightAnchor.constraint(equalTo: mediaContainer.heightAnchor, multiplier:  height).isActive = true
                } else {
                    gradientView.isHidden = true
                }
                if let color = gradient.colors.first?.hexStringToColor {
                    gradientView.gradientColors = [color, color.withAlphaComponent(0.001)]
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
    
        if screenData.media == nil {
            gradientView.isHidden = true
        }
        
        gradientView.gradientDirection = .bottomToTop
    }
}
