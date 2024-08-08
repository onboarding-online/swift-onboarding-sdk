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
    
    @IBOutlet weak var collectionLeftPadding: NSLayoutConstraint!
    @IBOutlet weak var collectionRightPadding: NSLayoutConstraint!

    @IBOutlet weak var collectionTopPadding: NSLayoutConstraint!
    @IBOutlet weak var collectionBottomPadding: NSLayoutConstraint!
    
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
    
    
    func setupCollectionConstraintsWith(box: BoxProtocol?) {
        guard let box = box else { return }
        
        if let paddingLeft =  box.paddingLeft?.cgFloatValue {
            self.collectionLeftPadding.constant = paddingLeft
        } else {
            self.collectionLeftPadding.constant = 0.0
        }
        
        if let paddingRight =  box.paddingRight?.cgFloatValue {
            self.collectionRightPadding.constant = paddingRight
        } else {
            self.collectionRightPadding.constant = 0.0
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
