import UIKit
import ScreensGraph

public class BaseScreenGraphViewController: BaseOnboardingScreen, OnboardingScreenProtocol {
    
    var screen: Screen!
    var value: Any?
    var permissionValue: Bool?

    weak var delegate: OnboardingScreenDelegate?
}

public class BaseChildScreenGraphViewController: BaseOnboardingViewController, OnboardingBodyChildScreenProtocol {
    weak var delegate: OnboardingChildScreenDelegate?
    var isEmbedded: Bool { true }
}

public class BaseChildScreenGraphListViewController: BaseChildScreenGraphViewController {
    
    @IBOutlet weak var mediaContainerView: UIView!
    @IBOutlet weak var mediaContainerViewHeightConstraint: NSLayoutConstraint!
    
    var videoPreparationService: VideoPreparationService? = nil
    var screen: Screen? = nil
    var media: Media?

    
    var videoBackground: VideoBackground? = nil

    
    func setupBackgroundFor(screenId: String,
                            using preparationService: VideoPreparationService) {
        if let status = preparationService.getStatusFor(screenId: screenId),
           case .ready(let preparedData) = status {
            playVideoBackgroundWith(preparedData: preparedData)
        } else {
            preparationService.observeScreenId(screenId) { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .undefined, .preparing:
                        return
                    case .failed:
                        break
                    case .ready(let preparedData):
                        self?.playVideoBackgroundWith(preparedData: preparedData)
                    }
                }
            }
        }
    }
    
    func playVideoBackgroundWith(preparedData: VideoBackgroundPreparedData) {
        if self.videoBackground == nil {
            self.videoBackground = VideoBackground()
            if let mode = media?.styles.scaleMode?.videoContentMode() {
                videoBackground?.videoGravity = mode
            }
            self.videoBackground!.play(in: self.mediaContainerView,
                                        using: preparedData)
        }
    }
}

public class BaseCollectionChildScreenGraphViewController: BaseChildScreenGraphViewController {
    
    static let listVideoKeyConstant =  "listVideo"
    @IBOutlet weak var collectionView: UICollectionView!

    @IBOutlet weak var collectionLeftPadding: NSLayoutConstraint!
    @IBOutlet weak var collectionRightPadding: NSLayoutConstraint!

    @IBOutlet weak var collectionTopPadding: NSLayoutConstraint!
    @IBOutlet weak var collectionBottomPadding: NSLayoutConstraint!
    
    @IBOutlet weak var mediaContainerView: UIView!
    @IBOutlet weak var mediaContainerViewHeightConstraint: NSLayoutConstraint!
    
    var videoPreparationService: VideoPreparationService? = nil
    var screen: Screen? = nil
    var media: Media?
    
    let imageView = UIImageView()
    let videoView = UIView()

    var videoBackground: VideoBackground? = nil

    func setupMedia() {
        if let media = media, let strongScreen = screen  {
            if media.kind == .image {
                wrapInUIView(padding: media.box.styles)
                load(image: media.image(), in: imageView, useLocalAssetsIfAvailable: strongScreen.useLocalAssetsIfAvailable)
            } else {
                wrapVideoInUIView(padding: media.box.styles)
                
                let screenID = strongScreen.id + BaseCollectionChildScreenGraphViewController.listVideoKeyConstant
                setupBackgroundFor(screenId: screenID, using: videoPreparationService!)
            }
        }
    }
    
    func wrapInUIView(padding: BoxBlock? = nil) {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .clear
        mediaContainerView.addSubview(imageView)
        
        let bottom = -1 * (padding?.paddingBottom ?? 0)
        let trailing = -1 * (padding?.paddingRight ?? 0)
        
        let leading = (padding?.paddingLeft ?? 0)
        let top = (padding?.paddingTop ?? 0)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: mediaContainerView.topAnchor, constant: top),
            imageView.bottomAnchor.constraint(equalTo: mediaContainerView.bottomAnchor, constant: bottom),
            imageView.leadingAnchor.constraint(equalTo: mediaContainerView.leadingAnchor, constant: leading),
            imageView.trailingAnchor.constraint(equalTo: mediaContainerView.trailingAnchor, constant: trailing)
        ])
    }
    
    func wrapVideoInUIView(padding: BoxBlock? = nil) {
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.backgroundColor = .clear
        mediaContainerView.addSubview(videoView)
        
        let bottom = -1 * (padding?.paddingBottom ?? 0)
        let trailing = -1 * (padding?.paddingRight ?? 0)
        
        let leading = (padding?.paddingLeft ?? 0)
        let top = (padding?.paddingTop ?? 0)
        
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: mediaContainerView.topAnchor, constant: top),
            videoView.bottomAnchor.constraint(equalTo: mediaContainerView.bottomAnchor, constant: bottom),
            videoView.leadingAnchor.constraint(equalTo: mediaContainerView.leadingAnchor, constant: leading),
            videoView.trailingAnchor.constraint(equalTo: mediaContainerView.trailingAnchor, constant: trailing)
        ])
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMedia()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let media = media {
            if let percent = media.styles.heightPercentage {
                mediaContainerViewHeightConstraint.constant = view.bounds.height * (percent / 100)
            } else {
                mediaContainerViewHeightConstraint.constant = view.bounds.height - collectionView.contentSize.height
            }
        } else {
            mediaContainerViewHeightConstraint.constant = 0
        }
    }
    
    func setupBackgroundFor(screenId: String,
                            using preparationService: VideoPreparationService) {
        if let status = preparationService.getStatusFor(screenId: screenId),
           case .ready(let preparedData) = status {
            playVideoBackgroundWith(preparedData: preparedData)
        } else {
            preparationService.observeScreenId(screenId) { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .undefined, .preparing:
                        return
                    case .failed:
                        break
                    case .ready(let preparedData):
                        self?.playVideoBackgroundWith(preparedData: preparedData)
                    }
                }
            }
        }
    }
    
    func playVideoBackgroundWith(preparedData: VideoBackgroundPreparedData) {
        if self.videoBackground == nil {
            self.videoBackground = VideoBackground()
            if let mode = media?.styles.scaleMode?.videoContentMode() {
                videoBackground?.videoGravity = mode
            }
            self.videoBackground!.play(in: self.videoView,
                                        using: preparedData)
        }
    }
    
    
    func setupCollectionConstraintsWith(box: BoxProtocol?) {
        guard let box = box else { return }
        var basePaddingLeft: CGFloat = 0.0
        var basePaddingRight: CGFloat = 0.0

        if let screen = screen {
            if screen.containerToTop() || screen.containerTillLeftRightParentView() {
                basePaddingLeft = 16.0
                basePaddingRight = 16.0
            }
        }
        
        if let paddingLeft =  box.paddingLeft?.cgFloatValue {
            self.collectionLeftPadding.constant = paddingLeft + basePaddingLeft
        } else {
            self.collectionLeftPadding.constant = basePaddingLeft
        }
        
        if let paddingRight =  box.paddingRight?.cgFloatValue {
            self.collectionRightPadding.constant = paddingRight + basePaddingRight
        } else {
            self.collectionRightPadding.constant = basePaddingRight
        }
    }
    
}


public class BaseOnboardingViewController: UIViewController, BaseViewControllerProtocol,  UIImageLoader  {
    
    var loadingIndicator: LoadingIndicatorView?
        
    fileprivate(set) var keyboardFrame: CGRect = .zero
    fileprivate(set) var keyboardAnimationDuration: TimeInterval = 0.25
    fileprivate(set) var keyboardAppeared = false
    var animationEnabled = false


    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBar()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if animationEnabled {
            runInitialAnimation()
        }
    }

    func runInitialAnimation() { } // Override when needed
}

extension BaseOnboardingViewController {
    
    func updateBackgroundImage(imageName: String) {
        let backgroundImage = UIImage(named: imageName)
        let backgroundImageView = UIImageView(frame: self.view.frame)
        backgroundImageView.image = backgroundImage
        self.view.insertSubview(backgroundImageView, at: 0)
    }

    func setupNavBar() {
        navigationItem.hidesBackButton = true
    }

}
