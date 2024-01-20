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
    
    func load(image: Image?, in imageView: UIImageView) {
        guard let image = image else { return }

        if let url = image.assetUrlByLocal()?.assetUrl?.origin, let imageURL = URL(string: url) {
            // Check local resources first
            if let imageString = url.resourceName()  {
                if let image = UIImage.init(named: imageString) {
                    if imageView.image != image {
                        imageView.setImage(image, animated: true)
                    }
                    return
                }
            }
            
            imageView.image = nil
            AssetsLoadingService.shared.loadImageFromURL(imageURL, intoView: imageView, placeholderImageName: nil)
        } else  if let assetName = image.assetUrlByLocal()?.assetName, let image = UIImage.init(named: assetName)  {
            if imageView.image != image {
                imageView.setImage(image, animated: true)
            }
        } else {
            imageView.image = nil
        }
    }
    
    func load(image: BaseImage?, in button: UIButton) {
        guard let image = image else { return }

        if let url = image.assetUrlByLocal()?.assetUrl?.origin {
            // Check local resources first
            if let imageString = url.resourceName()  {
                if let image = UIImage.init(named: imageString) {
                    button.setBackgroundImage(image, for: .normal)

                    return
                }
            }
            
            button.setBackgroundImage(nil, for: .normal)
            Task { @MainActor in
                let image = await AssetsLoadingService.shared.loadImage(from: url)
                button.setBackgroundImage(image, for: .normal)
            }
        } else  if let assetName = image.assetUrlByLocal()?.assetName, let image = UIImage.init(named: assetName)  {
            button.setBackgroundImage(image, for: .normal)
        } else {
            button.setBackgroundImage(nil, for: .normal)
        }
    }
}
