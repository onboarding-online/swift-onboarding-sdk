//
//  File.swift
//  
//
//  Copyright 2023 Onboarding.online on 18.03.2023.
//

import UIKit

final class LoadingIndicatorView: UIView {
    private(set) var isAnimating: Bool = false
    
    private var duration: TimeInterval = 1.2
    private var percentComplete = 0.0
    private var animationLayer: CAShapeLayer!
    private let backgroundView = UIView()
    
    private let rotationAnimationKey = "rotation.animation"
    private let strokeAnimationKey = "stroke.animation"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        baseInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        baseInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        animationLayer.frame = bounds
        updatePath()
    }
    
    convenience init() {
        let size: CGFloat = 32
        self.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

// MARK: - Public functions
extension LoadingIndicatorView {
    
    func startAnimating() {
        guard !isAnimating else { return }
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.duration = self.duration / 0.375
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = Float.pi * 2
        rotationAnimation.repeatCount = .infinity
        rotationAnimation.isRemovedOnCompletion = false
        animationLayer.add(rotationAnimation, forKey: rotationAnimationKey)
        
        let tailAnimation = CABasicAnimation(keyPath: "strokeStart")
        tailAnimation.duration = self.duration / 1.75
        tailAnimation.beginTime = self.duration / 4.5
        tailAnimation.fromValue = 0
        tailAnimation.toValue = 1
        tailAnimation.fillMode = .forwards
        tailAnimation.timingFunction = .init(controlPoints: 0.4, 0, 1, 1)
        
        let headAnimation = CABasicAnimation(keyPath: "strokeEnd")
        headAnimation.duration = self.duration / 2
        headAnimation.fromValue = 0
        headAnimation.toValue = 1
        headAnimation.fillMode = .backwards
        headAnimation.timingFunction = .init(controlPoints: 0.2, 0, 0.8, 1)
        
        let animations = CAAnimationGroup()
        animations.duration = self.duration
        animations.animations = [tailAnimation, headAnimation]
        animations.repeatCount = .infinity
        animations.isRemovedOnCompletion = false
        animationLayer.add(animations, forKey: strokeAnimationKey)
        
        isAnimating = true
    }
    
    func stopAnimating() {
        guard isAnimating else { return }
        
        animationLayer.removeAnimation(forKey: rotationAnimationKey)
        animationLayer.removeAnimation(forKey: strokeAnimationKey)
        isAnimating = false
    }
}

// MARK: - Private methods
private extension LoadingIndicatorView {
    func baseInit() {
        animationLayer = CAShapeLayer()
        animationLayer.strokeColor = UIColor.black.cgColor
        animationLayer.fillColor = nil
        animationLayer.lineCap = .round
        animationLayer.lineWidth = 3
        
        layer.addSublayer(animationLayer)
        NotificationCenter.default.addObserver(self, selector: #selector(resetAnimations), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func updatePath() {
        let radius = (bounds.width / 2) - (animationLayer.lineWidth / 2)
        let path = UIBezierPath(arcCenter: localCenter, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        animationLayer.path = path.cgPath
    }
    
    @objc func resetAnimations() {
        if isAnimating {
            stopAnimating()
            startAnimating()
        }
    }
    
}
