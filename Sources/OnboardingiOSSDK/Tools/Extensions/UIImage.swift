//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 03.02.2024.
//

import UIKit

extension UIImage {
    static func createWith(name: String) async -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: nil) else { return nil }
        
        return await createFrom(url: url)
    }
    
    static func createFrom(url: URL) async -> UIImage? {
        guard let imageData = try? Data(contentsOf: url) else { return nil }
        
        return await createFrom(imageData: imageData)
    }
    
    static func createFrom(imageData: Data) async -> UIImage? {
        if let gif = await GIFImageCreator.shared.createGIFImageWithData(imageData) {
            return gif
        }
        return UIImage(data: imageData)
    }
    
    func readyToDisplay() async -> UIImage {
        if #available(iOS 15.0, *) {
            let preparedImage = await self.byPreparingForDisplay()
            return preparedImage ?? self
        } else {
            return self
        }
    }
}
