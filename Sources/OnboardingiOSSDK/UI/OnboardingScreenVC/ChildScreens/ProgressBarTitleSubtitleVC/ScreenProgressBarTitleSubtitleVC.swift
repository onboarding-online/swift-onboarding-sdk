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
    
    var titleLabel: UILabel!
    
    var subtitleLabel: UILabel!
    var descriptionLabel: UILabel!
    
    var slideImage: UIImageView! = UIImageView()
    
    var mainView: UIView! = UIView()
    
    var progressContentView: UIView! = UIView()
    
    var screenData: ScreenProgressBarTitle!
    var screen: Screen? = nil
    
    var progressView: CircularProgressView? = nil
    
    
    override func viewDidLoad() {
        setupMainStack(stackHeightMultiplier: 0.7, isStackAboveProgressView: true)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupProgressView()
    }
    
    
    func createImageTitleSubtitleVerticalStack() -> UIStackView {
        let bulletStackView = UIStackView()
        
        bulletStackView.translatesAutoresizingMaskIntoConstraints = false
        bulletStackView.axis = .vertical
        bulletStackView.distribution = .fill
        bulletStackView.alignment = .fill
        bulletStackView.backgroundColor = .clear
        return bulletStackView
    }
    
    func setupMainStack(stackHeightMultiplier: CGFloat, isStackAboveProgressView: Bool) {
        self.view.addSubview(mainView)
        
        // Закрепляем mainView по всем сторонам к основному view
        mainView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainView.topAnchor.constraint(equalTo: self.view.topAnchor),
            mainView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            mainView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            mainView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        // Настройка bulletStackView
        let bulletStackView = setupBulletStackView()
        
        // Настройка progressTitleContainerView
        let progressTitleContainerView = setupProgressTitleContainerView()
        
        // Добавляем bulletStackView и progressTitleContainerView в mainView
        mainView.addSubview(bulletStackView)
        mainView.addSubview(progressTitleContainerView)
        
        // Устанавливаем порядок отображения контейнеров в зависимости от параметра isStackAboveProgressView
        if isStackAboveProgressView {
            NSLayoutConstraint.activate([
                bulletStackView.topAnchor.constraint(equalTo: mainView.topAnchor),
                bulletStackView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
                bulletStackView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
                bulletStackView.heightAnchor.constraint(equalTo: mainView.heightAnchor, multiplier: stackHeightMultiplier),
                
                progressTitleContainerView.topAnchor.constraint(equalTo: bulletStackView.bottomAnchor),
                progressTitleContainerView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
                progressTitleContainerView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
                progressTitleContainerView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                progressTitleContainerView.topAnchor.constraint(equalTo: mainView.topAnchor),
                progressTitleContainerView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
                progressTitleContainerView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
                progressTitleContainerView.heightAnchor.constraint(equalTo: mainView.heightAnchor, multiplier: 1 - stackHeightMultiplier),
                
                bulletStackView.topAnchor.constraint(equalTo: progressTitleContainerView.bottomAnchor),
                bulletStackView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
                bulletStackView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
                bulletStackView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)
            ])
        }
    }
    
    func setupBulletStackView() -> UIStackView {
        let bulletStackView = createImageTitleSubtitleVerticalStack()
        bulletStackView.translatesAutoresizingMaskIntoConstraints = false
        bulletStackView.axis = .vertical
        bulletStackView.distribution = .fill
        bulletStackView.alignment = .fill
        
        slideImage.translatesAutoresizingMaskIntoConstraints = false
        slideImage.clipsToBounds = true
        
        slideImage.setContentHuggingPriority(.defaultHigh, for: .vertical)
        slideImage.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        subtitleLabel = buildLabel()
        descriptionLabel = buildLabel()
        
        var subtitleBox: BoxBlock? = nil
        var descriptionBox: BoxBlock? = nil

        
        if let item = screenData.progressBar.items.first {
            if let image = item.content.image {
                slideImage = build(image: image)
                
                let imageContainer = wrapInUIView(imageView: slideImage, padding: image.box.styles)
                bulletStackView.addArrangedSubview(imageContainer)
            }
            
            if let subtitle = item.content.subtitle {
                subtitleBox = subtitle.box.styles
                subtitleLabel.apply(text: subtitle)
            }
            
            if let description = item.content.description {
                descriptionBox = description.box.styles
                descriptionLabel.apply(text: description)
            }
        }
        
        
        let titleView = wrapLabelInUIView(label: subtitleLabel, padding: subtitleBox)
        bulletStackView.addArrangedSubview(titleView)
        
        let subtitleView = wrapLabelInUIView(label: descriptionLabel, padding: descriptionBox)
        
        bulletStackView.addArrangedSubview(subtitleView)
        
        return bulletStackView
    }
    
    func setupProgressTitleContainerView() -> UIView {
        let progressTitleContainerView = UIView()
        progressTitleContainerView.translatesAutoresizingMaskIntoConstraints = false
        progressTitleContainerView.backgroundColor = .clear
        
        // Добавляем прогресс вью и заголовок в контейнер
        progressContentView.translatesAutoresizingMaskIntoConstraints = false
        progressContentView.backgroundColor = .clear
        progressTitleContainerView.addSubview(progressContentView)
        
        titleLabel = buildLabel()
        
        var titleBox: BoxBlock? = nil
        if let item = screenData.progressBar.items.first {
            titleBox = item.content.title.box.styles
            descriptionLabel.apply(text: item.content.title)
        }
        
        let titleView = wrapLabelInUIView(label: titleLabel, padding: titleBox)
        
        progressTitleContainerView.addSubview(titleView)
        
        // Устанавливаем констрейнты для progressContentView и titleLabel
        NSLayoutConstraint.activate([
            progressContentView.topAnchor.constraint(equalTo: progressTitleContainerView.topAnchor),
            progressContentView.leadingAnchor.constraint(equalTo: progressTitleContainerView.leadingAnchor),
            progressContentView.trailingAnchor.constraint(equalTo: progressTitleContainerView.trailingAnchor),
            progressContentView.heightAnchor.constraint(equalTo: progressTitleContainerView.heightAnchor, multiplier: 0.7),
            
            titleView.topAnchor.constraint(equalTo: progressContentView.bottomAnchor),
            titleView.leadingAnchor.constraint(equalTo: progressTitleContainerView.leadingAnchor),
            titleView.trailingAnchor.constraint(equalTo: progressTitleContainerView.trailingAnchor),
            titleView.bottomAnchor.constraint(equalTo: progressTitleContainerView.bottomAnchor)
        ])
        
        return progressTitleContainerView
    }
}

extension ScreenProgressBarTitleSubtitleVC {
    func wrapInUIView(imageView: UIImageView, padding: BoxBlock? = nil) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        containerView.addSubview(imageView)
        containerView.clipsToBounds = true
        
        let bottom = -1 * (padding?.paddingBottom ?? 0)
        let trailing = -1 * (padding?.paddingRight ?? 0)
        
        let leading = (padding?.paddingLeft ?? 0)
        let top = (padding?.paddingTop ?? 0)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: top),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottom),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leading),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailing)
        ])
        
        return containerView
    }

    func buildLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        
        return label
    }
    
    func build(image: Image) -> UIImageView {
        let imageView = UIImageView.init()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        load(image: image, in: imageView, useLocalAssetsIfAvailable: screenData.useLocalAssetsIfAvailable)
        if let imageContentMode = image.imageContentMode() {
            imageView.contentMode = imageContentMode
        } else {
            imageView.contentMode = .scaleAspectFit
        }
        
        return imageView
    }
    
   
    
    
    func wrapLabelInUIView(label: UILabel, padding: BoxBlock? = nil) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        containerView.addSubview(label)
        
        let bottom = -1 * (padding?.paddingBottom ?? 0)
        let trailing = -1 * (padding?.paddingRight ?? 0)
        
        let leading = (padding?.paddingLeft ?? 0)
        let top = (padding?.paddingTop ?? 0)
        
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: top),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottom),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leading),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailing)
        ])
        
        return containerView
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
//        subtitleLabel.apply(text: screenData?.title)
//        titleLabel.text = ""
    }
    
    func setupProgressView() {
        guard progressView == nil, screenData.progressBar.timer.duration > 0  else {
            finishProgressAction()
            return
        }
        
        self.view.layoutSubviews()
        
        let rect = CGRect(x: 0, y: 0, width: progressContentView.bounds.height, height: progressContentView.bounds.height)
        progressView = CircularProgressView(frame: rect, lineWidth: 15, rounded: false, timeTofill: screenData.progressBar.timer.duration.doubleValue)
        
        guard let progressViewStrong = progressView else { return }

        progressViewStrong.progress = 1
        
        progressViewStrong.oneLabel.apply(text: self.screenData.progressBar.label.styles)

        progressViewStrong.progressColor = (screenData.progressBar.styles.color ?? "").hexStringToColor
        progressViewStrong.trackColor = (screenData.progressBar.styles.trackColor ?? "").hexStringToColor

        progressContentView.addSubview(progressViewStrong)
        progressViewStrong.center = CGPoint(x: progressContentView.bounds.width / 2 , y: progressContentView.bounds.height / 2)

        NSLayoutConstraint.activate([
            // Констрейнты для bulletStackView (верхняя половина экрана)
            progressViewStrong.topAnchor.constraint(equalTo: progressContentView.topAnchor),
            progressViewStrong.leadingAnchor.constraint(equalTo: progressContentView.leadingAnchor),
            progressViewStrong.trailingAnchor.constraint(equalTo: progressContentView.trailingAnchor),
            progressViewStrong.bottomAnchor.constraint(equalTo: progressContentView.bottomAnchor)
        ])
        
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
            } else {
                self?.titleLabel.isHidden = true
            }
            
            if let itemSubtitle = item?.content.title {
                self?.subtitleLabel.isHidden = false
                self?.subtitleLabel.apply(text: itemSubtitle)
            } else {
                self?.subtitleLabel.isHidden = true
            }
            
            if let itemDescription = item?.content.title {
                self?.descriptionLabel.isHidden = false
                self?.descriptionLabel.apply(text: itemDescription)
            } else {
                self?.descriptionLabel.isHidden = true
            }
            
            if let image = item?.content.image {
                
                if let imageView = self?.slideImage {
                    self?.load(image: image, in: imageView, useLocalAssetsIfAvailable: self?.screenData.useLocalAssetsIfAvailable ?? true)
                }

            } else {
                self?.slideImage.image = nil
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
