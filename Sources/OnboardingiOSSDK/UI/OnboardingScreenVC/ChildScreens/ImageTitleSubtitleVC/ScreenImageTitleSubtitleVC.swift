//
//  StoryboardExampleViewController.swift
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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    @IBOutlet weak var pageImage: UIImageView!
    @IBOutlet weak var labelsStackView: UIStackView!

        
    var screenData: ScreenImageTitleSubtitles!

    override func viewDidLoad() {
        super.viewDidLoad()
                
        setupImage()
        setupLabelsValue()
        setupImageContentMode()
    }
    
    override func runInitialAnimation() {
        super.runInitialAnimation()
        
        OnboardingAnimation.runAnimationOfType(.fade, in: [pageImage])
        OnboardingAnimation.runAnimationOfType(.fade, in: [titleLabel, subtitleLabel], delay: 0.2)
    }
    
    func setupImage() {
        load(image: screenData.image, in: pageImage, useLocalAssetsIfAvailable: screenData.useLocalAssetsIfAvailable)
    }
    
    func setupLabelsValue() {
        titleLabel.apply(text: screenData?.title)
        subtitleLabel.apply(text: screenData?.subtitle1)
    }
    
    func setupImageContentMode() {
        if let imageContentMode = screenData.image.imageContentMode() {
            pageImage.contentMode = imageContentMode
        } else {
            pageImage.contentMode = .scaleAspectFit
        }
    }
        
}


