//
//  StoryboardExampleViewController.swift
//
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import UIKit
import ScreensGraph


class ScreenPickerTitleSubtitleVC: BaseChildScreenGraphViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    @IBOutlet weak var dataPicker: UIPickerView!
    @IBOutlet weak var verticalStack: UIStackView!
    @IBOutlet weak var imageView: UIImageView!

    var image: Image? = nil
    
    var screenDataPicker: PickerScreenProtocol!
    
    static func instantiate(screenData: ScreenImageTitleSubtitlePicker) -> ScreenPickerTitleSubtitleVC {
        let imageTitleSubtitlePickerVC = ScreenPickerTitleSubtitleVC.storyBoardInstance()
        imageTitleSubtitlePickerVC.screenDataPicker = screenData
        
        imageTitleSubtitlePickerVC.image = screenData.image
        
        return imageTitleSubtitlePickerVC
    }
    
    static func instantiate(screenData: ScreenTitleSubtitlePicker) -> ScreenPickerTitleSubtitleVC {
        let titleSubtitlePickerVC = ScreenPickerTitleSubtitleVC.storyBoardInstance()
        titleSubtitlePickerVC.screenDataPicker = screenData

        return titleSubtitlePickerVC
    }

    override func viewDidLoad() {
        super.viewDidLoad()
                
        setupImage()
        setupLabelsValue()
        setupPicker()
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUserInputValue()
    }
    
    override func runInitialAnimation() {
        super.runInitialAnimation()
        
        OnboardingAnimation.runAnimationOfType(.moveAndFade(direction: .fromBottomToTop), in: [titleLabel, subtitleLabel])
    }
    
    func setupImage() {
        setupImageContentMode()
        load(image: image,
             in: imageView,
             useLocalAssetsIfAvailable: screenDataPicker.useLocalAssetsIfAvailable)
    }
    
    func setupImageContentMode() {
        if let imageContentMode = image?.imageContentMode() {
            imageView.contentMode = imageContentMode
        } else {
            imageView.contentMode = .scaleAspectFit
        }
    }
    
    func setupLabelsValue() {
        titleLabel.apply(text: screenDataPicker?.title)
        subtitleLabel.apply(text: screenDataPicker?.subtitle)
    }
    
}

extension ScreenPickerTitleSubtitleVC: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if  let items = screenDataPicker?.picker.pickerValuesFor(wheelIndex:component)  {
            return items[row]
        }
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateUserInputValue()
    }
    
}

extension ScreenPickerTitleSubtitleVC: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return screenDataPicker?.picker.wheels.count ?? 0
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if let items = screenDataPicker?.picker.pickerValuesFor(wheelIndex:component)  {
            return items.count
        }
       
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if  let items = screenDataPicker?.picker.pickerValuesFor(wheelIndex:component)  {
            let styles = screenDataPicker.picker.labelStyles
            let keys = items[row].attributesFor(font: styles.getFontSettings(), letterSpacing: nil, underlineStyle: nil, textColor:  styles.color?.hexStringToColor, alignment: nil, lineHeight: nil)
            
            return  NSMutableAttributedString(string: items[row], attributes: keys)
        }
        return nil
    }
}


private extension ScreenPickerTitleSubtitleVC {
    
    func updateUserInputValue() {
        let value = pickerSelectedValue()
        self.delegate?.onboardingChildScreenUpdate(value: value, description: nil, logAnalytics: true)
    }
    
    func pickerSelectedValue() -> String? {
        var pickerValue = ""
        
        if var wheelsCount = screenDataPicker?.picker.wheels.count, wheelsCount > 0  {
            wheelsCount -= 1
            for wheelIndex in 0...wheelsCount {
                let selectedRow = dataPicker.selectedRow(inComponent: wheelIndex)

                if  selectedRow != -1, let items = screenDataPicker?.picker.pickerValuesFor(wheelIndex: wheelIndex), items.count - 1 >= selectedRow  {
                    pickerValue += items[selectedRow]
                }
            }
        }
        return pickerValue
    }
    
    func setupPicker() {
        dataPicker.delegate = self
        dataPicker.dataSource = self
        
        switch screenDataPicker.picker.styles.verticalAlignment ?? .center {
        case .top:
            verticalStack.alignment = .top
        case .center:
            verticalStack.alignment = .center
        case .bottom:
            verticalStack.alignment = .bottom
        }
        
        dataPicker.apply(picker: screenDataPicker.picker)
    }
    
}




