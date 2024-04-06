//
//  StoryboardExampleViewController.swift
//
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import UIKit
import ScreensGraph

class ScreenImageTitleSubtitle1Subtitle2TimerVC: BaseChildScreenGraphViewController {
    
    static func instantiate(screenData: ScreenSlider, screen: Screen) -> ScreenImageTitleSubtitle1Subtitle2TimerVC {
        let sliderScreenVC = ScreenImageTitleSubtitle1Subtitle2TimerVC.storyBoardInstance()
        sliderScreenVC.screenData = screenData
        sliderScreenVC.screen = screen
        return sliderScreenVC
    }
    
    @IBOutlet weak var pageImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel1: UILabel!
    @IBOutlet weak var subtitleLabel2: UILabel!
    @IBOutlet weak var textBlockTopConstraint: NSLayoutConstraint!

    var isFinished : BoolCallback?
    var progressCallback : IntCallback?
    
    var animationStart: Double!
    var _displayLink: CADisplayLink!
    var timeToFill = 0.01

    var screen: Screen? = nil
    var screenData: ScreenSlider!

    var currentSliderItem: SliderItem? = nil

    var isProgressFinished = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupProgressView()
        isProgressFinished = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        isProgressFinished = true
    }
    
    override func runInitialAnimation() {
        super.runInitialAnimation()

        OnboardingAnimation.runAnimationOfType(.moveAndFade(direction: .fromBottomToTop), in: [pageImage])
        
        OnboardingAnimation.runAnimationOfType(.moveAndFade(direction: .fromBottomToTop), in: [titleLabel])
        OnboardingAnimation.runAnimationOfType(.moveAndFade(direction: .fromBottomToTop),  in: [ subtitleLabel1], delay: 0.3)
        OnboardingAnimation.runAnimationOfType(.moveAndFade(direction: .fromBottomToTop), in: [ subtitleLabel2], delay: 0.5)
    }
    
}

fileprivate extension  ScreenImageTitleSubtitle1Subtitle2TimerVC {
    
    func startTimer() {
          animationStart = CACurrentMediaTime()

         _displayLink = CADisplayLink(target: self, selector: #selector(update))
         _displayLink.preferredFramesPerSecond = 6
         _displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
     }
     
     @objc func update() {
         let elapsedTime = CACurrentMediaTime() - animationStart
         let progress = elapsedTime / self.timeToFill
         
         if progress >= 1.0 {
             if let isFinished = isFinished {
                 _displayLink.invalidate()
                 _displayLink = nil
                 
                 if let progressCallback = progressCallback {
                     progressCallback(100)
                 }

                 isFinished(true)
             }
         }

         if let progressCallback = progressCallback {
             let progressToPercent = progress * 100.0
             
             if let intValue =  progressToPercent.rounededTowardZeroInt {
                 progressCallback(intValue)
             } else {
                 progressCallback(100)
             }
         }
     }
   
}


fileprivate extension  ScreenImageTitleSubtitle1Subtitle2TimerVC {
    
    func setupProgressView() {
        timeToFill = screenData.slider.timer.duration.doubleValue
        startTimer()
       
        progressCallback = { [weak self](percentCount) in
            let progress = percentCount > 100 ? 100 : percentCount
            
            let item = self?.findItemFor(progress: progress)
            
            if let item = item, self?.currentSliderItem != item {
                self?.setupImageContentMode(item: item)
                self?.currentSliderItem = item
                self?.setupSliderFor(sliderItem: item)
                self?.runInitialAnimation()
            }
        }
        
        isFinished = { [weak self] (isFinished) in
            guard let strongSelf = self, !strongSelf.isProgressFinished else { return }
            
            strongSelf.isProgressFinished = true
            strongSelf.delegate?.onboardingChildScreenPerform(action: strongSelf.screenData.slider.timer.action)
            
            if let screen = strongSelf.screen {
                OnboardingService.shared.eventRegistered(event: .switchedToNewScreenOnTimer, params: [.screenID : screen.id, .screenName : screen.name])
            }
        }
    }
    
    func findItemFor(progress: Int) -> SliderItem? {
        let item = screenData.slider.items.first(where: { item in
            if (progress >= item.valueFrom)  && (progress < item.valueTo) {
                return true
            } else {
                return false
            }
        })
        
        return item
    }
    
    func setupImage(item: SliderItem) {
        load(image: item.content.image, in: pageImage,
             useLocalAssetsIfAvailable: screen?.useLocalAssetsIfAvailable ?? true)
    }
    
    func setupSliderFor(sliderItem: SliderItem) {
        moveUpTextBlockIfImageIsEmpty(sliderItem: sliderItem)
        resetLabelsToDefaultState()
        
        let content = sliderItem.content

        switch screenData.slider.kind {
        case .image:
            setupImage(item: sliderItem)
        case .imageTitle:
            setupImage(item: sliderItem)
            titleLabel.apply(text: content.title)
        case .imageTitleSubtitle1:
            setupImage(item: sliderItem)
            titleLabel.apply(text: content.title)
            subtitleLabel1.apply(text: content.subtitle1)
        case .imageTitleSubtitle1Subtitle2:
            setupImage(item: sliderItem)
            titleLabel.apply(text: content.title)
            subtitleLabel1.apply(text: content.subtitle1)
            subtitleLabel2.apply(text: content.subtitle2)
        }
    }
    
    func resetLabelsToDefaultState() {
        titleLabel.isHidden = false
        subtitleLabel1.isHidden = false
        subtitleLabel2.isHidden = false
        subtitleLabel2.isHidden = false
    }
    
    func setupImageContentMode(item: SliderItem?) {
        if let imageContentMode = item?.content.image.imageContentMode() {
            pageImage.contentMode = imageContentMode
        } else {
            pageImage.contentMode = .scaleAspectFit
        }
    }
    
    func moveUpTextBlockIfImageIsEmpty(sliderItem: SliderItem) {
        if let asset = sliderItem.content.image.assetUrlByLocale(), asset.assetUrl == nil, (asset.assetName ?? "").isEmpty {
            textBlockTopConstraint.constant = -60
        } else {
            textBlockTopConstraint.constant = 0
        }
    }
    
}



