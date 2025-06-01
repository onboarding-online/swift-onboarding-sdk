//
//  File.swift
//  
//
//  Copyright 2023 Onboarding.online on 18.03.2023.
//

import UIKit
import ScreensGraph

protocol UIImageLoader { }

extension UIImageLoader {
    
    func load(
        image: Image?,
        in imageView: UIImageView,
        useLocalAssetsIfAvailable: Bool,
        animated: Bool = true
    ) {
        if let cornerRadius = image?.styles.mainCornerRadius {
            imageView.layer.cornerRadius = cornerRadius
        }

        Task { @MainActor in
            
            guard let image = await image?.loadImage(useLocalAssetsIfAvailable: useLocalAssetsIfAvailable) else {
                imageView.image = nil
                return
            }
            if imageView.image != image {
                imageView.setImage(image, animated: animated)
            }
        }
    }
    
    func loadLocalFirst(image: Image?, in imageView: UIImageView, useLocalAssetsIfAvailable: Bool) {
        if let cornerRadius = image?.styles.mainCornerRadius {
            imageView.layer.cornerRadius = cornerRadius
        }
        
        if let image = image {
            let urlByLocale = image.assetUrlByLocale()
            
            if !useLocalAssetsIfAvailable,
               let url = urlByLocale?.assetUrl?.origin {
                if let localImage = AssetsLoadingService.shared.loadLocalImageImage(from: url) {
                    imageView.setImage(localImage, animated: false)
                    return
                }
            }
        }

        Task { @MainActor in
            
            guard let image = await image?.loadImage(useLocalAssetsIfAvailable: useLocalAssetsIfAvailable) else {
                imageView.image = nil
                return
            }
            if imageView.image != image {
                imageView.setImage(image, animated: true)
            }
        }
    }
    
    func load(image: BaseImage?, in imageView: UIImageView, useLocalAssetsIfAvailable: Bool) {
        if let cornerRadius = image?.styles.mainCornerRadius {
            imageView.layer.cornerRadius = cornerRadius
        }

        Task { @MainActor in
            
            guard let image = await image?.loadImage(useLocalAssetsIfAvailable: useLocalAssetsIfAvailable) else {
                imageView.image = nil
                return
            }
            if imageView.image != image {
                imageView.setImage(image, animated: true)
            }
        }
    }
    
    func applyScaleModeAndLoad(image: Image?, in imageView: UIImageView, useLocalAssetsIfAvailable: Bool) {
        Task { @MainActor in
            self.load(image: image, in: imageView, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
            if let imageContentMode = image?.imageContentMode() {
                imageView.contentMode = imageContentMode
            } else {
                imageView.contentMode = .scaleAspectFit
            }
        }
    }
    
    func applyScaleModeAndLoad(image: BaseImage?, in imageView: UIImageView, useLocalAssetsIfAvailable: Bool) {
        Task { @MainActor in
            self.load(image: image, in: imageView, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
            if let imageContentMode = image?.imageContentMode() {
                imageView.contentMode = imageContentMode
            } else {
                imageView.contentMode = .scaleAspectFit
            }
        }
    }
    
    func load(image: BaseImage?, in button: UIButton, useLocalAssetsIfAvailable: Bool) {
        Task { @MainActor in
            guard let image = await image?.loadImage(useLocalAssetsIfAvailable: useLocalAssetsIfAvailable) else {
                button.setBackgroundImage(nil, for: .normal)
                return
            }
            
            button.setBackgroundImage(image, for: .normal)
        }
    }
}
