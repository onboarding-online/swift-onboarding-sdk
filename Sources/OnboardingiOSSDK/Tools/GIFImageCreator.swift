//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 02.02.2024.
//

import UIKit

final class GIFImageCreator {
    
    static let shared = GIFImageCreator()
    
    private let downloadedImageMaxSize: CGFloat = 512
    
    private init() { }
    
}

// MARK: - Open methods
extension GIFImageCreator {
    func createGIFImageWithData(_ data: Data,
                                maskingType: GIFMaskingType? = nil) async -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        do {
            let image = try await animatedImageWithSource(source, maskingType: maskingType)
            return image
        } catch GIFPreparationError.oneOrLessFrames {
            return nil /// Don't log this error
        } catch {
            OnboardingLogger.logError("Failed to create GIF image: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - GIF animations. Use GIFAnimationsService to work with GIF animations
private extension GIFImageCreator {
    func animatedImageWithSource(_ source: CGImageSource,
                                 maskingType: GIFMaskingType?) async throws -> UIImage {
        let count = CGImageSourceGetCount(source)
        let (images, delays) = try await extractImagesWithDelays(from: source, maskingType: maskingType)
        
        let duration: Int = {
            var sum = 0
            
            for val: Int in delays {
                sum += val
            }
            
            return sum
        }()
        
        let gcd = try gcdForArray(delays)
        var frames = [UIImage]()
        
        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)
            
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        
        guard let animation = UIImage.animatedImage(with: frames,
                                                    duration: Double(duration) / 1000.0) else {
            throw GIFPreparationError.failedToCreateAnimatedImage
        }
        
        return animation
    }
    
    func extractImagesWithDelays(from source: CGImageSource,
                                 maskingType: GIFMaskingType?) async throws -> ImagesWithDelays {
        guard let cgContext = CGContext(data: nil, width: 10, height: 10, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: 0) else {
            throw GIFPreparationError.failedToCreateCGContext
        }
        let count = CGImageSourceGetCount(source)
        if count <= 1 {
            throw GIFPreparationError.oneOrLessFrames
        }
        guard let cgImage = cgContext.makeImage() else {
            throw GIFPreparationError.failedToMakeCGImage
        }
        var images = [CGImage](repeating: cgImage, count: count)
        var delays = [Int](repeating: 0, count: count)
        try await withThrowingTaskGroup(of: ImageToIndex.self, body: { group in
            let downsampleOptions = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true
            ] as CFDictionary
            let sharedContext = CIContext(options: [.useSoftwareRenderer : false,
                                                    .highQualityDownsample: true])
            
            
            /// 1. Fill group with tasks
            for i in 0..<count {
                group.addTask {
                    guard let image = CGImageSourceCreateImageAtIndex(source, i, downsampleOptions),
                          let maskedImage = self.createCGImage(image, withMaskingType: maskingType),
                          let resizedImage = self.resizedImage(maskedImage,
                                                               scale: self.scaleForImage(image),
                                                               in: sharedContext) else {
                        throw GIFPreparationError.failedToGetImageFromSource
                    }
                    
                    let delaySeconds = try self.delayForImageAtIndex(Int(i),
                                                                     source: source)
                    
                    /// Note: This block capturing self.
                    return ImageToIndex(image: resizedImage,
                                        delay: delaySeconds,
                                        i: i)
                }
            }
            
            /// 2. Take values from group
            for try await imageToIndex in group {
                let i = imageToIndex.i
                
                images.replaceSubrange(i...i, with: [imageToIndex.image])
                delays.replaceSubrange(i...i, with: [Int(imageToIndex.delay * 1000.0)]) // Seconds to ms
            }
        })
        
        return (images, delays)
    }
    
    func createCGImage(_ image: CGImage, withMaskingType maskingType: GIFMaskingType?) -> CGImage? {
        guard let maskingType else { return image }
        
        return image.copy(maskingColorComponents: maskingType.maskingColorComponents)
    }
    
    func scaleForImage(_ image: CGImage) -> CGFloat {
        let maxSize = max(image.height, image.width)
        let scale = min(1, downloadedImageMaxSize / CGFloat(maxSize))
        return scale
    }
    
    func resizedImage(_ cgImage: CGImage, scale: CGFloat, in sharedContext: CIContext) -> CGImage? {
        guard scale != 1 else { return cgImage }
        
        return autoreleasepool {
            let image = CIImage(cgImage: cgImage)
            let filter = CIFilter(name: "CILanczosScaleTransform")
            filter?.setValue(image, forKey: kCIInputImageKey)
            filter?.setValue(scale, forKey: kCIInputScaleKey)
            filter?.setValue(1, forKey: kCIInputAspectRatioKey)
            
            guard let outputCIImage = filter?.outputImage,
                  let outputCGImage = sharedContext.createCGImage(outputCIImage,
                                                                  from: outputCIImage.extent)
            else {
                return nil
            }
            
            return outputCGImage
        }
    }
    
    func delayForImageAtIndex(_ index: Int, source: CGImageSource) throws -> Double {
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        
        var value = CFDictionaryGetValue(cfProperties, unsafeBitCast(kCGImagePropertyGIFDictionary, to: UnsafeRawPointer.self))
        if value == nil {
            if #available(iOS 14.0, *) {
                value = CFDictionaryGetValue(cfProperties, unsafeBitCast(kCGImagePropertyWebPDictionary, to: UnsafeRawPointer.self))
            }
        }
        
        guard let value else { throw GIFPreparationError.failedToCastDelay }
        
        let gifProperties: CFDictionary = unsafeBitCast(value,
                                                        to: CFDictionary.self)
        
        
        var delayObject: AnyObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                                        Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
                                                   to: AnyObject.self)
        
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                             Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        guard let delayDouble = delayObject as? Double else {
            throw GIFPreparationError.failedToCastDelay
        }
        
        return delayDouble
    }
    
    func gcdForPair(_ a: Int, _ b: Int) throws -> Int {
        var a = a
        var b = b
        
        
        if a < b {
            let c = a
            a = b
            b = c
        }
        
        var rest: Int
        while true {
            guard b != 0 else { throw GIFPreparationError.divisionByZero }
            
            rest = a % b
            
            if rest == 0 {
                return b
            } else {
                a = b
                b = rest
            }
        }
    }
    
    func gcdForArray(_ array: Array<Int>) throws -> Int {
        if array.isEmpty {
            return 1
        }
        
        var gcd = array[0]
        
        for val in array {
            gcd = try gcdForPair(val, gcd)
        }
        
        return gcd
    }
    
    enum GIFPreparationError: String, LocalizedError {
        case divisionByZero
        case failedToCreateAnimatedImage
        case failedToCreateCGContext
        case failedToMakeCGImage
        case failedToGetImageFromSource
        case failedToCastDelay
        case oneOrLessFrames
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}

// MARK: - Entities
private extension GIFImageCreator {
    struct ImageToIndex {
        let image: CGImage
        let delay: Double
        let i: Int
    }
    
    typealias ImagesWithDelays = ([CGImage], [Int])
}

enum GIFMaskingType {
    case maskWhite
    
    var maskingColorComponents: [CGFloat] {
        switch self {
        case .maskWhite:
            return [222, 255, 222, 255, 222, 255]
        }
    }
}
