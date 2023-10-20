//
//  StoryboardExampleViewController.swift
//
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//

import UIKit
import ScreensGraph


class ScreenProgressBarTitleSubtitleVC: BaseChildScreenGraphViewController {
    
    static func instantiate(screenData: ScreenProgressBarTitle, screen: Screen) -> ScreenProgressBarTitleSubtitleVC {
        let progressBarVC = ScreenProgressBarTitleSubtitleVC.storyBoardInstance()
        progressBarVC.screenData = screenData
        progressBarVC.screen = screen

        return progressBarVC
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var progressContentView: UIView!
    
    var screenData: ScreenProgressBarTitle!
    var screen: Screen? = nil

    var progressView: CircularProgressView? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupLabelsValue()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupProgressView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if progressView != nil {
            progressView?.isFinished = nil
            progressView?.removeFromSuperview()
            progressView = nil
        }
    }
    
    func setupLabelsValue() {
        subtitleLabel.apply(text: screenData?.title)
        titleLabel.text = ""
    }
    
    func setupProgressView() {
        guard progressView == nil, screenData.progressBar.timer.duration > 0  else {
            finishProgressAction()
            return
        }
        
        self.view.layoutSubviews()
        progressView = CircularProgressView(frame: progressContentView.bounds, lineWidth: 15, rounded: false, timeTofill: screenData.progressBar.timer.duration.doubleValue)
        
        guard let progressViewStrong = progressView else { return }

        progressViewStrong.progress = 1
        
        progressViewStrong.oneLabel.apply(text: self.screenData.progressBar.label.styles)

        progressViewStrong.progressColor = (screenData.progressBar.styles.color ?? "").hexStringToColor
        progressViewStrong.trackColor = (screenData.progressBar.styles.trackColor ?? "").hexStringToColor

        progressContentView.addSubview(progressViewStrong)
        progressViewStrong.center = CGPoint(x: progressContentView.bounds.width / 2 , y: progressContentView.bounds.height / 2)

        
        progressViewStrong.progressCallback = { [weak self](percentCount) in
            let progress = percentCount > 100 ? 100 : percentCount
            progressViewStrong.oneLabel.text = "\(progress)%"
            
            let item = self?.screenData.progressBar.items.first(where: { item in
                if (progress >= item.valueFrom)  && (progress < item.valueTo) {
                    return true
                } else {
                    return false
                }
            })

            if let itemTitle = item?.content.title {
                self?.titleLabel.isHidden = false
                self?.titleLabel.apply(text: itemTitle)
            }
        }
        
        progressViewStrong.isFinished = { [weak self] (isFinished) in

            guard let strongSelf = self, isFinished else { return }
            strongSelf.delegate?.onboardingChildScreenPerform(action: strongSelf.screenData.progressBar.timer.action)
            if let screen = strongSelf.screen {
                OnboardingService.shared.eventRegistered(event: .switchedToNewScreenOnTimer, params: [.screenID : screen.id, .screenName : screen.name])
            }
        }
    }
    
    func finishProgressAction() {
        delegate?.onboardingChildScreenPerform(action: screenData.progressBar.timer.action)
        if let screen = screen {
            OnboardingService.shared.eventRegistered(event: .switchedToNewScreenOnTimer, params: [.screenID : screen.id, .screenName : screen.name])
        }
    }

}


class CircularProgressView: UIView {
    var isFinished : BoolCallback?
    var progressCallback : IntCallback?

    fileprivate var progressLayer = CAShapeLayer()
    fileprivate var trackLayer = CAShapeLayer()
    fileprivate var didConfigureLabel = false
    fileprivate var rounded: Bool
    fileprivate var filled: Bool
    
    var oneLabel = UILabel()
    private var pathCenter: CGPoint{ get{ return self.convert(self.center, from:self.superview) } }
    private func configLabel(){
        oneLabel.sizeToFit()
        let size = self.bounds.width 
        oneLabel.frame = CGRect(x: 0, y: 0, width: size, height: size)
        oneLabel.text = "0 %"
        oneLabel.font = UIFont.systemFont(ofSize: 40)
        oneLabel.textAlignment = .center
        oneLabel.center = pathCenter
    }
    
    var animationStart: Double!
    var _displayLink: CADisplayLink!
    
    fileprivate let lineWidth: CGFloat?
    
    var timeToFill = 0.01
    
    var progressColor = UIColor.white {
        didSet{
            progressLayer.strokeColor = progressColor.cgColor
        }
    }
    
    var trackColor = UIColor.green {
        didSet{
            trackLayer.strokeColor = trackColor.cgColor
        }
    }
    
    var progress: Float {
        didSet{
            var pathMoved = progress - oldValue
            if pathMoved < 0 {
                pathMoved = 0 - pathMoved
            }
            
            setProgress(duration: timeToFill * Double(pathMoved), to: progress)
        }
    }
    
    fileprivate func createProgressView(){
        self.backgroundColor = .clear
        let widthOfLine  = lineWidth ?? 15
        let radius = frame.width / 2 - (widthOfLine / 2)
        let circularPath = UIBezierPath(arcCenter: CGPoint(x: frame.width / 2, y: frame.height / 2), radius: radius , startAngle: CGFloat(-0.5 * .pi), endAngle: CGFloat(1.5 * .pi), clockwise: true)
        trackLayer.fillColor = UIColor.blue.cgColor
        
        
        trackLayer.path = circularPath.cgPath
        trackLayer.fillColor = .none
        trackLayer.strokeColor = trackColor.cgColor
        if filled {
            trackLayer.lineCap = .butt
            trackLayer.lineWidth = frame.width
        }else{
            trackLayer.lineWidth = lineWidth!
        }
        trackLayer.strokeEnd = 1
        layer.addSublayer(trackLayer)
        
        progressLayer.path = circularPath.cgPath
        progressLayer.fillColor = .none
        progressLayer.strokeColor = progressColor.cgColor
        if filled {
            progressLayer.lineCap = .butt
            progressLayer.lineWidth = frame.width
        }else{
            progressLayer.lineWidth = lineWidth!
        }
        progressLayer.strokeEnd = 0
        if rounded {
            progressLayer.lineCap = .round
        }
        
        configLabel()

        self.addSubview(oneLabel)

        layer.addSublayer(progressLayer)
    }
    
    func trackColorToProgressColor() -> Void {
        trackColor = progressColor

    }
    
    func setProgress(duration: TimeInterval = 3, to newProgress: Float) -> Void{
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        
        animation.duration = duration
        
        animation.fromValue = progressLayer.strokeEnd
        animation.toValue = newProgress
        
        progressLayer.strokeEnd = CGFloat(newProgress)
        progressLayer.add(animation, forKey: "animationProgress")
        
        animationStart = CACurrentMediaTime()

        _displayLink = CADisplayLink(target: self, selector: #selector(update))
        _displayLink.preferredFramesPerSecond = 6
        _displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
    }
    
    @objc func update() {

        let elapsedTime = CACurrentMediaTime() - animationStart
        let  progress1 = elapsedTime / self.timeToFill
        
        if progress1 >= 1.0 {
            if let isFinished = isFinished {
                if _displayLink != nil {
                    isFinished(true)
                }
                
                _displayLink.invalidate()
                _displayLink = nil
                animationStart = 0.0
                
            }
        }

        if let progressCallback = progressCallback {
            let intValue = (progress1 * 100).intValue
            progressCallback(intValue)
        }
    }
    
    
    override init(frame: CGRect){
        progress = 0
        rounded = true
        filled = false
        lineWidth = 15
        super.init(frame: frame)
        filled = false
        createProgressView()
    }
    
    required init?(coder: NSCoder) {
        progress = 0
        rounded = true
        filled = false
        lineWidth = 15
        super.init(coder: coder)
        createProgressView()
        
    }
    
    init(frame: CGRect, lineWidth: CGFloat?, rounded: Bool, timeTofill: Double) {
        progress = 0
        
        if lineWidth == nil{
            self.filled = true
            self.rounded = false
        }else{
            if rounded{
                self.rounded = true
            }else{
                self.rounded = false
            }
            self.filled = false
        }
        self.lineWidth = lineWidth
        self.timeToFill = timeTofill
        
        super.init(frame: frame)
        createProgressView()
    }
    
}
