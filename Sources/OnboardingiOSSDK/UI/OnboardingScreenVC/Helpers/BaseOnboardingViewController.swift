import UIKit
import ScreensGraph

class BaseScreenGraphViewController: BaseOnboardingViewController, OnboardingScreenProtocol {
    
    var screen: Screen!
    var value: Any?
    var permissionValue: Bool?

    weak var delegate: OnboardingScreenDelegate?
}

class BaseChildScreenGraphViewController: BaseOnboardingViewController, OnboardingBodyChildScreenProtocol {
    weak var delegate: OnboardingChildScreenDelegate?
    var isEmbedded: Bool { true }
}

class BaseOnboardingViewController: UIViewController, BaseViewControllerProtocol,  UIImageLoader  {
    
    var loadingIndicator: LoadingIndicatorView?
        
    fileprivate(set) var keyboardFrame: CGRect = .zero
    fileprivate(set) var keyboardAnimationDuration: TimeInterval = 0.25
    fileprivate(set) var keyboardAppeared = false
    var animationEnabled = false


    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBar()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
