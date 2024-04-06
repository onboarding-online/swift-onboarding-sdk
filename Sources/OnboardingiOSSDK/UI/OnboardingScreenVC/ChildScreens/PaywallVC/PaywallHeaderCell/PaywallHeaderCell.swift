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

    private var videoBackground: VideoBackground? = nil

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

extension ScreenBasicPaywall {
   
    func image()-> BaseImage? {
        switch self.media?.content {
        case .typeMediaImage(let image):
            return image.image
        default:
            return nil
        }
    }
    
}

// MARK: - Open methods
extension PaywallHeaderCell {
    
    func imageHeaderSetup() {
        var bottomPadding = screenData.media?.box.styles.paddingBottom ?? 0

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
        
        if let box = screenData.media?.box {
            imageViewContainerTopConstraint.constant = box.styles.paddingTop ?? 0
            imageViewContainerTrailingConstraint.constant = box.styles.paddingRight ?? 0
            imageViewContainerLeadingConstraint.constant = box.styles.paddingLeft ?? 0
        }
            
        if let imageContentMode = screenData.media?.styles.scaleMode?.imageContentMode() {
            imageView.contentMode = imageContentMode
        } else {
            imageView.contentMode = .scaleAspectFit
        }
    }
    
    func setWith() {
        setWithStyle()
        if screenData.media?.kind == .image {
            load(image: screenData.image(), in: imageView)
        }
    }
    
    func setWith(paywallData: ScreenBasicPaywall) {
        screenData = paywallData
        setWithStyle()
        imageHeaderSetup()
        if screenData.media?.kind == .image {
            load(image: screenData.image(), in: imageView)
//            load(image: screenData.image(), in: imageView)
        }
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

        if self.videoBackground == nil {
            self.videoBackground = VideoBackground()
            self.videoBackground!.play(in: self.imageViewContainer,
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
    
    func setWithStyle() {
        contentStackView.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        
        let titleLabel = buildTitleLabel()
        let subtitleLabel = buildLabel()
        
        titleLabel.apply(text: screenData.title)
        subtitleLabel.apply(text: screenData.subtitle)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let titleView = wrapLabelInUIView(label: titleLabel, padding: screenData.title.styles)
        let subTitleView = wrapLabelInUIView(label: subtitleLabel, padding: screenData.subtitle.styles)

        contentStackView.addArrangedSubview(titleView)
        contentStackView.addArrangedSubview(subTitleView)
        
        applyListSettings()
        
        let bulletStackView = UIStackView()
        bulletStackView.axis = .vertical
        bulletStackView.distribution = .fillProportionally
        bulletStackView.alignment = .fill
        bulletStackView.spacing = screenData.list.styles.itemsSpacing ?? 8
        
        for item in screenData.list.items {
            let title = buildLabel()
            title.apply(text: item.title)
            let subTitle = buildLabel()
            subTitle.apply(text: item.subtitle)
            
            let titleView = wrapLabelInUIView(label: title)
            let subTitleView = wrapLabelInUIView(label: subTitle)

            let checkmark = buildBulletCheckmark(image: item.image)
            checkmark.clipsToBounds = true
            
//            checkmark.translatesAutoresizingMaskIntoConstraints = false

            let vStack = UIStackView(arrangedSubviews: [titleView, subTitleView])
            vStack.translatesAutoresizingMaskIntoConstraints = false
            vStack.distribution = .fill
            vStack.alignment = .leading
            vStack.axis = .vertical
            vStack.spacing = 4
               
            
            title.setContentHuggingPriority(.defaultHigh, for: .vertical) // Для вертикального стека
            title.setContentCompressionResistancePriority(.defaultHigh, for: .vertical) // Для вертикального стека

            subTitle.setContentHuggingPriority(.defaultHigh, for: .vertical) // Для вертикального стека
            subTitle.setContentCompressionResistancePriority(.defaultHigh, for: .vertical) // Для вертикального стека

            
            titleView.setContentHuggingPriority(.defaultHigh, for: .vertical) // Для вертикального стека
            subTitleView.setContentHuggingPriority(.defaultHigh, for: .vertical) // Для вертикального стека
           
            vStack.setContentHuggingPriority(.defaultHigh, for: .vertical) // Для вертикального стека
            vStack.setContentCompressionResistancePriority(.defaultHigh, for: .vertical) // Для вертикального стека
            vStack.setContentHuggingPriority(.defaultHigh, for: .horizontal) // Для вертикального стека
            vStack.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal) // Для вертикального стека
            
            
            checkmark.setContentHuggingPriority(.defaultLow, for: .vertical) // Для вертикального стека
            checkmark.setContentCompressionResistancePriority(.defaultHigh, for: .vertical) // Для вертикального стека
            
            checkmark.setContentHuggingPriority(.defaultLow, for: .horizontal) // Для вертикального стека
            checkmark.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal) // Для вертикального стека
            
          
           
            
            
            let hStack = UIStackView(arrangedSubviews: [checkmark, vStack])
            hStack.distribution = .fill
            hStack.alignment = .leading
            hStack.axis = .horizontal
            hStack.spacing = 16
            hStack.translatesAutoresizingMaskIntoConstraints = false

            bulletStackView.addArrangedSubview(hStack)
            bulletStackView.translatesAutoresizingMaskIntoConstraints = false
        }
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        contentStackView.addArrangedSubview(bulletStackView)
        
        setupGradient()
    }
    
    func wrapLabelInUIView(label: UILabel, padding: LabelBlock? = nil) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear // Прозрачный фон для контейнера, можно изменить по желанию.
        
        // Добавляем label в containerView.
        containerView.addSubview(label)
        
        // Включаем использование Auto Layout для label.
        label.translatesAutoresizingMaskIntoConstraints = false
        if let padding = padding {
            // Применяем ограничения к label для центрирования внутри containerView и добавления отступов.
            
            let bottom = -1 * (padding.paddingBottom ?? 0)
            let trailing = -1 * (padding.paddingRight ?? 0)

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding.paddingTop ?? 0),
                label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottom),
                label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding.paddingLeft ?? 0),
                label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailing)
            ])
        } else {
            // Применяем ограничения к label для центрирования внутри containerView и добавления отступов.
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
        let width = image.styles.width ?? 24
        let height = image.styles.height ?? 24
       
        let imageView = UIImageView.init()
//        
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

//        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([imageView.widthAnchor.constraint(equalToConstant: width),
                                     imageView.heightAnchor.constraint(equalToConstant: height)])
        
        applyScaleModeAndLoad(image: image, in: imageView)
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
