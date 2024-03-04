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
        Task { @MainActor in
            guard let image = await image?.loadImage() else {
                imageView.image = nil
                return
            }
            if imageView.image != image {
                imageView.setImage(image, animated: true)
            }
        }
    }
    
    func applyScaleModeAndLoad(image: Image?, in imageView: UIImageView) {
        Task { @MainActor in
            self.load(image: image, in: imageView)
            if let imageContentMode = image?.imageContentMode() {
                imageView.contentMode = imageContentMode
            } else {
                imageView.contentMode = .scaleAspectFit
            }
        }
    }
    
    func load(image: BaseImage?, in button: UIButton) {
        Task { @MainActor in
            guard let image = await image?.loadImage() else {
                button.setBackgroundImage(nil, for: .normal)
                return
            }
            
            button.setBackgroundImage(image, for: .normal)
        }
    }
}
