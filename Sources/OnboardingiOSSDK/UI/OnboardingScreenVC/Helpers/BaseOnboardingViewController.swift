import UIKit
import ScreensGraph

class BaseScreenGraphViewController: BaseOnboardingViewController, OnboardingScreenProtocol {
    
    var screen: Screen!
    var value: Any?
    var permissionValue: Bool?

    weak var delegate: OnboardingScreenDelegate?
}

public class BaseChildScreenGraphViewController: BaseOnboardingViewController, OnboardingBodyChildScreenProtocol {
    weak var delegate: OnboardingChildScreenDelegate?
    var isEmbedded: Bool { true }
}

public class BaseCollectionChildScreenGraphViewController: BaseChildScreenGraphViewController {

    @IBOutlet weak var collectionLeftPadding: NSLayoutConstraint!
    @IBOutlet weak var collectionRightPadding: NSLayoutConstraint!

    @IBOutlet weak var collectionTopPadding: NSLayoutConstraint!
    @IBOutlet weak var collectionBottomPadding: NSLayoutConstraint!
    
    
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

        if let paddingTop =  box.paddingTop?.cgFloatValue {
            self.collectionTopPadding.constant = paddingTop
        } else {
            self.collectionTopPadding.constant = 0.0
        }

        if let paddingBottom =  box.paddingBottom?.cgFloatValue {
            self.collectionBottomPadding.constant = paddingBottom
        } else {
            self.collectionBottomPadding.constant = 0.0
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
