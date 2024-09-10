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
    
    var imageViewTopConstraint: NSLayoutConstraint!
    var imageViewBottomConstraint: NSLayoutConstraint!
    var imageViewLeadingConstraint: NSLayoutConstraint!
    var imageViewTrailingConstraint: NSLayoutConstraint!
    
    var titleTopConstraint: NSLayoutConstraint!
    var titleBottomConstraint: NSLayoutConstraint!
    var titleLeadingConstraint: NSLayoutConstraint!
    var titleTrailingConstraint: NSLayoutConstraint!
    
    var subtitleTopConstraint: NSLayoutConstraint!
    var subtitleBottomConstraint: NSLayoutConstraint!
    var subtitleLeadingConstraint: NSLayoutConstraint!
    var subtitleTrailingConstraint: NSLayoutConstraint!
    
    
    var descriptionTopConstraint: NSLayoutConstraint!
    var descriptionBottomConstraint: NSLayoutConstraint!
    var descriptionLeadingConstraint: NSLayoutConstraint!
    var descriptionTrailingConstraint: NSLayoutConstraint!
    
    var staticTitleLabel: UILabel? = nil

    var titleLabel: UILabel!
    var titleLabelContainer: UIView!
    
    var subtitleLabel: UILabel!
    var subtitleLabelContainer: UIView!
    
    var descriptionLabel: UILabel!
    var descriptionLabelContainer: UIView!
    
    var slideImage: UIImageView!
    
    var mainView: UIView! = UIView()
    
    var progressContentView: UIView!
    
    var screenData: ScreenProgressBarTitle!
    var screen: Screen? = nil
    
    var progressView: CircularProgressView? = nil
    
    var currentItem: ProgressBarItem? = nil


    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressContentView = UIView()
        slideImage = UIImageView()
        titleLabelContainer = UIView()
        subtitleLabelContainer = UIView()
        descriptionLabelContainer = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let width = (screenData.progressBar.styles.heightPercentage ?? 50.0) / 100.0
        setupMainStack(stackHeightMultiplier: width, progressBarKind: screenData.progressBar.kind)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        

        setupProgressView()
    }
    
}
fileprivate extension ScreenProgressBarTitleSubtitleVC {
    
    func createImageTitleSubtitleVerticalStack() -> UIStackView {
        let bulletStackView = UIStackView()
        
        bulletStackView.translatesAutoresizingMaskIntoConstraints = false
        bulletStackView.axis = .vertical
        bulletStackView.distribution = .fill
        bulletStackView.alignment = .fill
        bulletStackView.spacing = 0
        bulletStackView.backgroundColor = .clear
        return bulletStackView
    }
    
    func createHorizontalStack() -> UIStackView {
        let bulletStackView = UIStackView()
        
        bulletStackView.translatesAutoresizingMaskIntoConstraints = false
        bulletStackView.axis = .horizontal
        bulletStackView.distribution = .fill
        bulletStackView.alignment = .top
        return bulletStackView
    }
    
    func setupMainStack(stackHeightMultiplier: CGFloat, progressBarKind: ProgressBarKind) {
        self.view.addSubview(mainView)
        
        // Закрепляем mainView по всем сторонам к основному view
        mainView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainView.topAnchor.constraint(equalTo: self.view.topAnchor),
            mainView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            mainView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            mainView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        // Настройка progressTitleContainerView
        let progressTitleContainerView = setupProgressTitleContainerView(fullHeight: progressBarKind == .circle)
        
        switch progressBarKind {
        case .progressBarKind1:
            // Настройка bulletStackView
            let bulletStackView = setupBulletStackView()
            
            // Добавляем bulletStackView и progressTitleContainerView в mainView
            mainView.addSubview(bulletStackView)
            mainView.addSubview(progressTitleContainerView)
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
        case .progressBarKind2:
            // Настройка bulletStackView
            let bulletStackView = setupBulletStackView()
            
            // Добавляем bulletStackView и progressTitleContainerView в mainView
            mainView.addSubview(bulletStackView)
            mainView.addSubview(progressTitleContainerView)
            
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
        default:
            // Создаем вспомогательную view для вычисления отступа
            let topSpacerView = UIView()
            topSpacerView.translatesAutoresizingMaskIntoConstraints = false
            mainView.addSubview(topSpacerView)

            // Добавляем progressTitleContainerView в mainView
            mainView.addSubview(progressTitleContainerView)
            
            NSLayoutConstraint.activate([
                // Устанавливаем topSpacerView на 25% высоты mainView
                topSpacerView.topAnchor.constraint(equalTo: mainView.topAnchor),
                topSpacerView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
                topSpacerView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
                topSpacerView.heightAnchor.constraint(equalTo: mainView.heightAnchor, multiplier: 0.25),

                // Устанавливаем progressTitleContainerView под topSpacerView
                progressTitleContainerView.topAnchor.constraint(equalTo: topSpacerView.bottomAnchor),
                progressTitleContainerView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
                progressTitleContainerView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
                progressTitleContainerView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)
            ])
        }
    }
    
    func setupBulletStackView() -> UIStackView {
        let bulletStackView = createImageTitleSubtitleVerticalStack()
        bulletStackView.translatesAutoresizingMaskIntoConstraints = false
        bulletStackView.axis = .vertical
        bulletStackView.distribution = .fill
        bulletStackView.alignment = .fill
        
                                            
        subtitleLabel = buildLabel()
        descriptionLabel = buildLabel()
        
        var subtitleBox: BoxBlock? = nil
        var descriptionBox: BoxBlock? = nil

        
        if let item = screenData.progressBar.items.first {
            if let image = item.content.image {
                slideImage = build(image: image)
                slideImage.translatesAutoresizingMaskIntoConstraints = false
                slideImage.setContentHuggingPriority(.defaultLow, for: .vertical)
                slideImage.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
                
            
                let imageContainer = wrapInUIView(imageView: slideImage, padding: image.box.styles)
                bulletStackView.addArrangedSubview(imageContainer)
            }
            
            if let subtitle = item.content.subtitle {
                subtitleBox = subtitle.box.styles
//                subtitleLabel.apply(text: subtitle)
            }
            
            if let description = item.content.description {
                descriptionBox = description.box.styles
//                descriptionLabel.apply(text: description)
            }
        }
        
        
        _ = wrapLabelInUIView(label: subtitleLabel, view: subtitleLabelContainer, padding: subtitleBox)
        subtitleLabelContainer.layoutIfNeeded()
        bulletStackView.addArrangedSubview(subtitleLabelContainer)
        
        _ = wrapLabelInUIView(label: descriptionLabel, view: descriptionLabelContainer, padding: descriptionBox)
        descriptionLabelContainer.layoutIfNeeded()

        bulletStackView.addArrangedSubview(descriptionLabelContainer)
        
        return bulletStackView
    }
    
    func setupProgressTitleContainerView(fullHeight: Bool) -> UIView {
        let progressTitleContainerView = UIView()
        progressTitleContainerView.translatesAutoresizingMaskIntoConstraints = false
        progressTitleContainerView.backgroundColor = .clear
        
        // Добавляем прогресс вью и заголовок в контейнер
        progressContentView.translatesAutoresizingMaskIntoConstraints = false
        progressContentView.backgroundColor = .clear
        
        let progressContainerView = UIView()
        progressContainerView.translatesAutoresizingMaskIntoConstraints = false
        progressContainerView.backgroundColor = .clear

        progressTitleContainerView.addSubview(progressContainerView)

        progressContainerView.addSubview(progressContentView)
        
        titleLabel = buildLabel()
        
        var titleBox: BoxBlock? = nil
        if let item = screenData.progressBar.items.first {
            titleBox = item.content.title.box.styles
            titleLabel.apply(text: item.content.title)
        }
        
        let titleView = wrapLabelInUIView(label: titleLabel, view: titleLabelContainer, padding: titleBox)
        let stack = createHorizontalStack()
        
        let verticalStack = createImageTitleSubtitleVerticalStack()
        verticalStack.clipsToBounds = true

        
        verticalStack.addArrangedSubview(titleView)
        
        if screenData.progressBar.kind == .circle && !screenData.title.textByLocale().isEmpty {
            staticTitleLabel = buildLabel()
            if let mainScreenTitleLabel = staticTitleLabel {
                mainScreenTitleLabel.apply(text: screenData.title)
                let mainScreenTitleLabelView = wrapLabelInUIView(label: mainScreenTitleLabel, view: UIView(), padding: screenData.title.box.styles)

                verticalStack.addArrangedSubview(mainScreenTitleLabelView)
            }
        }
        
        stack.addArrangedSubview(verticalStack)
        stack.clipsToBounds = true
        
        progressTitleContainerView.addSubview(stack)
        
        let paddingBottom = (screenData.progressBar.box.styles.paddingBottom ?? 0.0) * -1.0
        let paddingTop = (screenData.progressBar.box.styles.paddingTop ?? 0.0)
        let paddingRight = (screenData.progressBar.box.styles.paddingRight ?? 0.0) * -1.0
        let paddingLeft = (screenData.progressBar.box.styles.paddingLeft ?? 0.0)
        
        let progressContainerHeightPercentage = ((screenData.progressBar.styles.height ?? 75.0) / 100.0).cgFloatValue
        
        if fullHeight {
            // Устанавливаем констрейнты для progressContentView и titleLabel
            NSLayoutConstraint.activate([
                
                progressContainerView.topAnchor.constraint(equalTo: progressTitleContainerView.topAnchor),
                progressContainerView.centerXAnchor.constraint(equalTo: progressTitleContainerView.centerXAnchor), // Центрируем по горизонтали
                progressContainerView.widthAnchor.constraint(equalTo: progressTitleContainerView.widthAnchor, multiplier: 0.75), // Устанавливаем ширину 75% от супервью
                progressContainerView.heightAnchor.constraint(equalTo: progressContentView.widthAnchor), // Высота равна ширине
                
                progressContentView.topAnchor.constraint(equalTo: progressContainerView.topAnchor, constant: paddingTop),
                progressContentView.leadingAnchor.constraint(equalTo: progressContainerView.leadingAnchor, constant: paddingLeft),
                progressContentView.trailingAnchor.constraint(equalTo: progressContainerView.trailingAnchor, constant: paddingRight),
                progressContentView.bottomAnchor.constraint(equalTo: progressContainerView.bottomAnchor, constant: paddingBottom),

                stack.topAnchor.constraint(equalTo: progressContainerView.bottomAnchor),
                stack.leadingAnchor.constraint(equalTo: progressTitleContainerView.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: progressTitleContainerView.trailingAnchor),
                stack.bottomAnchor.constraint(equalTo: progressTitleContainerView.bottomAnchor)
            ])
        } else {
            // Устанавливаем констрейнты для progressContentView и titleLabel
            NSLayoutConstraint.activate([
                // Контейнер прогресса получает 0.7 высота всего контейнера с прогресом и тайтлом
                progressContainerView.topAnchor.constraint(equalTo: progressTitleContainerView.topAnchor),
                progressContainerView.leadingAnchor.constraint(equalTo: progressTitleContainerView.leadingAnchor),
                progressContainerView.trailingAnchor.constraint(equalTo: progressTitleContainerView.trailingAnchor),
                progressContainerView.heightAnchor.constraint(equalTo: progressTitleContainerView.heightAnchor, multiplier: progressContainerHeightPercentage),
                
                // В прогрес контейнер встраивается еще один контейнер в который будет вписываться прогресс и применяться констренйты
                progressContentView.topAnchor.constraint(equalTo: progressContainerView.topAnchor, constant: paddingTop),
                progressContentView.leadingAnchor.constraint(equalTo: progressContainerView.leadingAnchor, constant: 0.0),
                progressContentView.trailingAnchor.constraint(equalTo: progressContainerView.trailingAnchor, constant: 0.0),
                progressContentView.bottomAnchor.constraint(equalTo: progressContainerView.bottomAnchor, constant: paddingBottom),
                
                // Вертикальный стек с лейблами привязывается к низу контейнера с прогрессом
                stack.topAnchor.constraint(equalTo: progressContainerView.bottomAnchor),
                stack.leadingAnchor.constraint(equalTo: progressTitleContainerView.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: progressTitleContainerView.trailingAnchor),
                
                stack.bottomAnchor.constraint(equalTo: progressTitleContainerView.bottomAnchor)
            ])
        }
       
        
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
        
        imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: top)
        imageViewBottomConstraint = imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottom)
        imageViewLeadingConstraint = imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leading)
        imageViewTrailingConstraint = imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailing)
        
        NSLayoutConstraint.activate([
            imageViewTopConstraint,
            imageViewBottomConstraint,
            imageViewLeadingConstraint,
            imageViewTrailingConstraint
        ])
        
        return containerView
    }
    
    func update(image: Image) {
        let padding = image.box.styles
        
        let bottom = -1 * (padding.paddingBottom ?? 0)
        let trailing = -1 * (padding.paddingRight ?? 0)
        
        let leading = (padding.paddingLeft ?? 0)
        let top = (padding.paddingTop ?? 0)
        
        imageViewTopConstraint.constant = top
        imageViewBottomConstraint.constant = bottom
        imageViewLeadingConstraint.constant = leading
        imageViewTrailingConstraint.constant = trailing
        
        slideImage.updateConstraints()
        
        if let imageContentMode = image.imageContentMode() {
            slideImage.contentMode = imageContentMode
        } else {
            slideImage.contentMode = .scaleAspectFit
        }
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
        imageView.clipsToBounds = true
//        loadLocalFirst(image: image, in: imageView, useLocalAssetsIfAvailable: screenData.useLocalAssetsIfAvailable)
//        load(image: image, in: imageView, useLocalAssetsIfAvailable: screenData.useLocalAssetsIfAvailable)
        
        if let imageContentMode = image.imageContentMode() {
            imageView.contentMode = imageContentMode
        } else {
            imageView.contentMode = .scaleAspectFit
        }
        
        return imageView
    }
    
   
    func wrapLabelInUIView(label: UILabel, view: UIView, padding: BoxBlock? = nil) -> UIView {
        let containerView = view
        
        containerView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        containerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        containerView.addSubview(label)
        
        let bottom = -1 * (padding?.paddingBottom ?? 0)
        let trailing = -1 * (padding?.paddingRight ?? 0)
        
        let leading = (padding?.paddingLeft ?? 0)
        let top = (padding?.paddingTop ?? 0)
        
        if label == titleLabel {
            titleTopConstraint = label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: top)
            titleBottomConstraint = label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottom)
            titleLeadingConstraint = label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leading)
            titleTrailingConstraint = label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailing)

            titleTopConstraint.priority = .defaultLow
            titleBottomConstraint.priority = .defaultLow


            NSLayoutConstraint.activate([
                titleTopConstraint,
                titleBottomConstraint,
                titleLeadingConstraint,
                titleTrailingConstraint
            ])
        } else if label == subtitleLabel {
            subtitleTopConstraint = label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: top)
            subtitleBottomConstraint = label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottom)
            subtitleLeadingConstraint = label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leading)
            subtitleTrailingConstraint = label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailing)
            
            NSLayoutConstraint.activate([
                subtitleTopConstraint,
                subtitleBottomConstraint,
                subtitleLeadingConstraint,
                subtitleTrailingConstraint
            ])
        } else if label == descriptionLabel {
            descriptionTopConstraint = label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: top)
            descriptionBottomConstraint = label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottom)
            descriptionLeadingConstraint = label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leading)
            descriptionTrailingConstraint = label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailing)
            
            NSLayoutConstraint.activate([
                descriptionTopConstraint,
                descriptionBottomConstraint,
                descriptionLeadingConstraint,
                descriptionTrailingConstraint
            ])
        } else {
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: top),
                label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottom),
                label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leading),
                label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailing)
            ])
        }
        
        return containerView
    }
    
    func updateLabelInUIView(label: UILabel?, view: UIView?, padding: BoxBlock? = nil) {
        guard let label = label, let view = view else {
            return
        }
        
        let containerView = view
        view.clipsToBounds = true
        
        let bottom = -1 * (padding?.paddingBottom ?? 0)
        let trailing = -1 * (padding?.paddingRight ?? 0)
        
        let leading = (padding?.paddingLeft ?? 0)
        let top = (padding?.paddingTop ?? 0)
        
        if label == titleLabel {
            titleTopConstraint.constant = top
            titleBottomConstraint.constant = bottom
            titleLeadingConstraint.constant = leading
            titleTrailingConstraint.constant = trailing
        } else if label == subtitleLabel {
            subtitleTopConstraint.constant = top
            subtitleBottomConstraint.constant = bottom
            subtitleLeadingConstraint.constant = leading
            subtitleTrailingConstraint.constant = trailing
            
        } else if label == descriptionLabel {
            descriptionTopConstraint.constant = top
            descriptionBottomConstraint.constant = bottom
            descriptionLeadingConstraint.constant = leading
            descriptionTrailingConstraint.constant = trailing
        }
        
        containerView.layoutIfNeeded()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if progressView != nil {
            progressView?.isFinished = nil
            progressView?.removeFromSuperview()
            progressView = nil
        }
        
        if slideImage != nil {
            slideImage.removeFromSuperview()
            slideImage = nil
        }
        
        if descriptionLabel != nil {
            descriptionLabel.removeFromSuperview()
            descriptionLabel = nil
        }
        
        if subtitleLabel != nil {
            subtitleLabel.removeFromSuperview()
            subtitleLabel = nil
        }
        
        if titleLabel != nil {
            titleLabel.removeFromSuperview()
            titleLabel = nil
        }
        
        if staticTitleLabel != nil {
            staticTitleLabel?.removeFromSuperview()
            staticTitleLabel = nil
        }
    }
    
    func setupProgressView() {
        guard progressView == nil, screenData.progressBar.timer.duration > 0  else {
            finishProgressAction()
            return
        }
        
        self.view.layoutSubviews()
        
        let maxHeight = self.mainView.bounds.width * 0.75
        var height = progressContentView.bounds.height > progressContentView.bounds.width ? progressContentView.bounds.width : progressContentView.bounds.height
         height =  maxHeight > height ? height : maxHeight
        
        let rect = CGRect(x: 0, y: 0, width: height, height: height)

        let lineWidth = (screenData.progressBar.styles.thickness ?? 15.0).cgFloatValue
        
        progressView = CircularProgressView(frame: rect, lineWidth: lineWidth, rounded: false, timeTofill: screenData.progressBar.timer.duration.doubleValue)
        
        guard let progressViewStrong = progressView else { return }

        progressViewStrong.progress = 1
        
        progressViewStrong.oneLabel.apply(text: self.screenData.progressBar.label.styles)

        progressViewStrong.progressColor = (screenData.progressBar.styles.color ?? "").hexStringToColor
        progressViewStrong.trackColor = (screenData.progressBar.styles.trackColor ?? "").hexStringToColor

        progressContentView.addSubview(progressViewStrong)
        progressViewStrong.center = CGPoint(x: progressContentView.bounds.width / 2 , y: progressContentView.bounds.height / 2)

        NSLayoutConstraint.activate([
            // Констрейнты для bulletStackView (верхняя половина экрана)
//            progressViewStrong.topAnchor.constraint(equalTo: progressContentView.topAnchor),
//            progressViewStrong.leadingAnchor.constraint(equalTo: progressContentView.leadingAnchor),
//            progressViewStrong.trailingAnchor.constraint(equalTo: progressContentView.trailingAnchor),
//            progressViewStrong.bottomAnchor.constraint(equalTo: progressContentView.bottomAnchor)
        ])
        
        progressViewStrong.progressCallback = { [weak self](percentCount) in
            let progress = percentCount > 100 ? 100 : percentCount
            progressViewStrong.oneLabel.text = "\(progress)%"
            
            var item: ProgressBarItem? = nil
            
            if let items = self?.screenData.progressBar.items {
                for currentItem in items {
                    if (progress >= currentItem.valueFrom)  && (progress < currentItem.valueTo) {
                        item = currentItem
                    }
                }
            }
           
            if let item = item  {
                if self?.currentItem == item {
                    
                } else {
                    self?.currentItem = item
  
                    DispatchQueue.main.async { [weak self] in
                        
                        if  self?.titleLabel != nil {
                            let itemTitle = item.content.title
                            if !itemTitle.textByLocale().isEmpty {
                                self?.updateLabelInUIView(label: self?.titleLabel, view: self?.titleLabelContainer, padding: itemTitle.box.styles)

                                self?.titleLabel.isHidden = false
                                self?.titleLabelContainer.isHidden = false
                                self?.titleLabel.apply(text: itemTitle)
                            } else {
                                self?.titleLabel.isHidden = true
                                self?.titleLabelContainer.isHidden = true
                            }
                        }
                        
                        if  self?.subtitleLabel != nil {
                            if let itemSubtitle = item.content.subtitle, !itemSubtitle.textByLocale().isEmpty  {
                                self?.subtitleLabel.apply(text: itemSubtitle)
                                self?.updateLabelInUIView(label: self?.subtitleLabel, view: self?.subtitleLabelContainer, padding: itemSubtitle.box.styles)

                                self?.subtitleLabel.isHidden = false
                                self?.subtitleLabelContainer.isHidden = false
                            } else {
                                self?.subtitleLabel.isHidden = true
                                self?.subtitleLabelContainer.isHidden = true
                            }
                        }
                        
                        if  self?.descriptionLabel != nil {
                            if let itemDescription = item.content.description, !itemDescription.textByLocale().isEmpty   {
                                self?.descriptionLabel.apply(text: itemDescription)
                                self?.updateLabelInUIView(label: self?.descriptionLabel, view: self?.descriptionLabelContainer, padding: itemDescription.box.styles)
                                self?.descriptionLabel.isHidden = false
                                self?.descriptionLabelContainer.isHidden = false
                            } else {
                                self?.descriptionLabel.isHidden = true
                                self?.descriptionLabelContainer.isHidden = true
                            }
                        }
                        
                        
                        if let image = item.content.image {
                            
                            if let imageView = self?.slideImage {
                                self?.loadLocalFirst(image: image, in: imageView, useLocalAssetsIfAvailable: self?.screenData.useLocalAssetsIfAvailable ?? true)
                                self?.update(image: image)
                            }
                            
                        } else {
                            if (self?.slideImage) != nil {
                                self?.slideImage.image = nil
                            }
                        }
                        
                    }
                }

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
        let widthOfLine  = lineWidth ?? 10
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
