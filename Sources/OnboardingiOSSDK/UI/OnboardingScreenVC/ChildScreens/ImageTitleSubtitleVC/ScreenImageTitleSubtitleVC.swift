//
//  ScreenImageTitleSubtitleVC.swift
//
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import UIKit
import ScreensGraph

class ScreenImageTitleSubtitleVC: BaseChildScreenGraphViewController {
    
    static func instantiate(screenData: ScreenImageTitleSubtitles) -> ScreenImageTitleSubtitleVC {
        let  screenImageTitleSubtitleVC = ScreenImageTitleSubtitleVC.storyBoardInstance()
        screenImageTitleSubtitleVC.screenData = screenData
        return screenImageTitleSubtitleVC
    }
    
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!

    var pageImage: UIImageView!
    @IBOutlet weak var mainStackView: UIStackView!

    var imageScreenType = ImageKind.imageKind1

    var screenData: ScreenImageTitleSubtitles!

    override func viewDidLoad() {
        super.viewDidLoad()
                
        setupScreen()
    }
    
    func setupScreen() {
        if let imageKind =  screenData.image.styles.imageKind {
            imageScreenType = imageKind
        }
        
        titleLabel = buildLabel()
        subtitleLabel = buildLabel()
        setupLabelsValue()
        let titleLabelView = wrapLabelInUIView(label: titleLabel, padding: screenData.title.box.styles)
        let subtitleLabelView = wrapLabelInUIView(label: subtitleLabel, padding: screenData.subtitle1.box.styles)
        
        pageImage = build(image: screenData.image)
        pageImage.clipsToBounds = true
        let imageContainer = wrapInUIView(imageView: pageImage, padding: screenData.image.box.styles)
        
        if imageScreenType == .imageKind3 {
            mainStackView.addArrangedSubview(titleLabelView)
            mainStackView.addArrangedSubview(subtitleLabelView)
            mainStackView.addArrangedSubview(imageContainer)
        } else {
            mainStackView.addArrangedSubview(imageContainer)
            mainStackView.addArrangedSubview(titleLabelView)
            mainStackView.addArrangedSubview(subtitleLabelView)
        }
    }
    
    override func runInitialAnimation() {
        super.runInitialAnimation()
        
        if imageScreenType == .imageKind3 {
            OnboardingAnimation.runAnimationOfType(.fade, in: [titleLabel, subtitleLabel])
            OnboardingAnimation.runAnimationOfType(.fade, in: [pageImage], delay: 0.2)
        } else {
            OnboardingAnimation.runAnimationOfType(.fade, in: [pageImage])
            OnboardingAnimation.runAnimationOfType(.fade, in: [titleLabel, subtitleLabel], delay: 0.2)
        }
    }
    
    func setupImage() {
        load(image: screenData.image, in: pageImage, useLocalAssetsIfAvailable: screenData.useLocalAssetsIfAvailable)
    }
    
    func setupLabelsValue() {
        titleLabel.apply(text: screenData?.title)
        subtitleLabel.apply(text: screenData?.subtitle1)
    }
    
}

extension ScreenImageTitleSubtitleVC {
    
    func wrapLabelInUIView(label: UILabel, padding: BoxBlock? = nil) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        containerView.addSubview(label)
        
        containerView.setContentHuggingPriority(UILayoutPriority(300), for: .horizontal) // Для вертикального стека
        containerView.setContentCompressionResistancePriority(UILayoutPriority(800), for: .horizontal) // Для вертикальног
        
        let bottom = -1 * (padding?.paddingBottom ?? 0)
        var trailing = -1 * (padding?.paddingRight ?? 0)
        
        var leading = (padding?.paddingLeft ?? 0)
        let top = (padding?.paddingTop ?? 0)
        
        // Return default left and right paddings for child container with alignment to superview without safe area
        if imageScreenType == .imageKind2 {
            trailing -= 16
            leading += 16
        }
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: top),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottom),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leading),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailing)
        ])
        
        return containerView
    }
    
    func buildLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0

        label.setContentHuggingPriority(UILayoutPriority(300), for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriority(800), for: .horizontal)

        label.setContentHuggingPriority(UILayoutPriority(1000), for: .vertical)
        label.setContentCompressionResistancePriority(UILayoutPriority(800), for: .vertical)
        
        return label
    }
    
    func build(image: Image) -> UIImageView {
        let imageView = UIImageView.init()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        load(image: screenData.image, in: imageView, useLocalAssetsIfAvailable: screenData.useLocalAssetsIfAvailable)
        if let imageContentMode = screenData.image.imageContentMode() {
            imageView.contentMode = imageContentMode
        } else {
            imageView.contentMode = .scaleAspectFit
        }
        
        return imageView
    }
    
    
    func wrapInUIView(imageView: UIImageView, padding: BoxBlock? = nil) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        containerView.clipsToBounds = true
        containerView.addSubview(imageView)
        
        let bottom = -1 * (padding?.paddingBottom ?? 0)
        let trailing = -1 * (padding?.paddingRight ?? 0)
        
        let leading = (padding?.paddingLeft ?? 0)
        let top = (padding?.paddingTop ?? 0)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: top),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottom),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leading),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailing)
        ])
        
        return containerView
    }
}


