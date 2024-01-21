//
//  PaywallVC.swift
//  
//
//  Created by Oleg Kuplin on 26.12.2023.
//

import UIKit
import ScreensGraph
import StoreKit

// TODO: - Check for canMakePayments before showing paywall 
 public final class PaywallVC: BaseChildScreenGraphViewController {
    
    public static func instantiate(paymentService: OnboardingPaymentServiceProtocol) -> PaywallVC {
        let paywallVC = PaywallVC.nibInstance()
        paywallVC.paymentService = paymentService
        return paywallVC
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var bottomView: PaywallBottomView!
    @IBOutlet weak var gradientView: GradientView!
    
    override var isEmbedded: Bool { false }
    private var paymentService: OnboardingPaymentServiceProtocol!
    private var selectedIndex: Int = 0
    private var isLoadingProducts = true
    private var isBusy = true
    private var products: [StoreKitProduct] = []
    public var productIds: [String] = [] // TODO: - Set product ids
    var shouldCloseOnPurchaseCancel = false
    
    public var dismissalHandler: (() -> ())!


     public override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

}

// MARK: - PaywallBottomViewDelegate
extension PaywallVC: PaywallBottomViewDelegate {
    func paywallBottomViewBuyButtonPressed(_ paywallBottomView: PaywallBottomView) {
        delegate?.onboardingChildScreenUpdate(value: nil, 
                                              description: "Buy",
                                              logAnalytics: true)
        purchaseSelectedProduct()
    }
  
    func paywallBottomViewPPButtonPressed(_ paywallBottomView: PaywallBottomView) {
        delegate?.onboardingChildScreenUpdate(value: nil,
                                              description: "Privacy Policy",
                                              logAnalytics: true)
        showSafariWith(url: ppURL)
    }
    
    func paywallBottomViewTACButtonPressed(_ paywallBottomView: PaywallBottomView) {
        delegate?.onboardingChildScreenUpdate(value: nil,
                                              description: "Terms and conditions",
                                              logAnalytics: true)
        showSafariWith(url: tacURL)
    }
    
    func paywallBottomViewRestoreButtonPressed(_ paywallBottomView: PaywallBottomView) {
        delegate?.onboardingChildScreenUpdate(value: nil, 
                                              description: "Restore",
                                              logAnalytics: true)
        restoreProducts()
    }
}

// MARK: - UICollectionViewDataSource
extension PaywallVC: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        allSections().count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section = allSections()[section]
        
        return rowsFor(section: section).count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = allSections()[indexPath.section]
        let row = rowsFor(section: section)[indexPath.row]
        
        switch row {
        case .header(let configuration):
            let cell = collectionView.dequeueCellOfType(PaywallHeaderCell.self, at: indexPath)
            cell.setWith(configuration: configuration)

            return cell
        case .separator:
            let cell = collectionView.dequeueCellOfType(PaywallSeparatorCell.self, at: indexPath)
            return cell
        case .loading:
            let cell = collectionView.dequeueCellOfType(PaywallLoadingCell.self, at: indexPath)
            return cell
        case .listSubscription(let configuration):
            let index = indexPath.row
            let isSelected = selectedIndex == index
            
            let cell = collectionView.dequeueCellOfType(PaywallListSubscriptionCell.self, at: indexPath)
            cell.setWith(configuration: configuration, isSelected: isSelected)
            
            return cell
        case .oneTypePurchase(let configuration):
            let index = indexPath.row
            let isSelected = selectedIndex == index
            
            let cell = collectionView.dequeueCellOfType(PaywallListSubscriptionCell.self, at: indexPath)
            cell.setWith(configuration: configuration, isSelected: isSelected)
            
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate
extension PaywallVC: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = allSections()[indexPath.section]
        let row = rowsFor(section: section)[indexPath.row]
        
        switch row {
        case .header(_), .separator, .loading:
            return
        case .listSubscription, .oneTypePurchase:
            let index = indexPath.row
            if selectedIndex != index {
                var indexPathsToReload = [indexPath]
                indexPathsToReload.append(IndexPath(row: selectedIndex, section: indexPath.section))
                selectedIndex = index
                reloadCellsAt(indexPaths: indexPathsToReload)
                delegate?.onboardingChildScreenUpdate(value: indexPath.row, 
                                                      description: products[selectedIndex].id,
                                                      logAnalytics: true)
            }
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let headerCell = collectionView.visibleCells.first(where: { $0 is PaywallHeaderCell }) as? PaywallHeaderCell {
            headerCell.setScrollOffset(scrollView.contentOffset)
        }
    }
    
    func reloadCellsAt(indexPaths: [IndexPath]) {
        if #available(iOS 15.0, *) {
            collectionView.reconfigureItems(at: indexPaths)
        } else {
            collectionView.reloadItems(at: indexPaths)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PaywallVC: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sections = allSections()
        let section = sections[indexPath.section]
        let row = rowsFor(section: section)[indexPath.row]
        var height: CGFloat = 0
        switch row {
        case .header:
            height = calculateHeaderSize(in: sections)
        case .loading:
            let sectionsSpacing = CGFloat(sections.count - 1) * Constants.sectionsSpacing
            height = collectionView.bounds.height - Constants.defaultHeaderHeight - sectionsSpacing
        default:
            height = row.height
        }
        return .init(width: view.bounds.width, height: height)
    }
    
    func calculateHeaderSize(in sections: [SectionType]) -> CGFloat {
        if isLoadingProducts {
            return Constants.defaultHeaderHeight
        }
        var contentSize: CGFloat = 0
        for section in sections {
            switch section {
            case .header, .separator:
                contentSize += Constants.sectionsSpacing
            case .items:
                let items = rowsFor(section: section)
                if !items.isEmpty {
                    let itemsHeight = items.reduce(0, { $0 + $1.height })
                    let spacingHeight = CGFloat(items.count - 1) * Constants.listItemsSpacing
                    contentSize += (itemsHeight + spacingHeight)
                }
            }
        }
        
        return collectionView.bounds.height - contentSize
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let section = allSections()[section]
        
        switch section {
        case .header, .separator:
            return 0
        case .items:
            return Constants.listItemsSpacing
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let section = allSections()[section]
        switch section {
        case .header, .separator:
            return .init(top: 0, left: 0,
                         bottom: Constants.sectionsSpacing, right: 0)
        case .items:
            return .zero
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }
}

// MARK: - Private methods
private extension PaywallVC {
    private var ppURL: URL { 
        URL(string: "https://google.com")! // TODO: - Set PP URL
    }
    private var tacURL: URL {
        URL(string: "https://google.com")! // TODO: - Set TAC URL
    }
    
    func loadProducts() {
        delegate?.onboardingChildScreenUpdate(value: nil, 
                                              description: "Will load products",
                                              logAnalytics: true)

        Task {
            do {
                let products = try await paymentService.fetchProductsWith(ids: Set(productIds))
                delegate?.onboardingChildScreenUpdate(value: nil,
                                                      description: "Did load products: \(products.map { $0.productIdentifier })",
                                                      logAnalytics: true)
                self.products = products
                    .compactMap( { StoreKitProduct(skProduct: $0) })
                    .sorted(by: { lhs, rhs in
                        guard let lhsIndex = productIds.firstIndex(where: { $0 == lhs.id }),
                              let rhsIndex = productIds.firstIndex(where: { $0 == rhs.id }) else {
                            return false
                        }
                        
                        return lhsIndex < rhsIndex
                    })
                didLoadProducts()
            } catch {
                delegate?.onboardingChildScreenUpdate(value: nil,
                                                      description: "Did fail to load products: \(error.localizedDescription)",
                                                      logAnalytics: true)
                handleError(error, message: "Something went wrong") { [weak self] in
                    self?.loadProducts()
                }
            }
        }
    }
    
    func restoreProducts() {
        setViewBusy(true)
        Task {
            do {
                try await paymentService?.restorePurchases()
                delegate?.onboardingChildScreenUpdate(value: nil, 
                                                      description: "Did restore purchases",
                                                      logAnalytics: true)
                let hasActiveSubscription = try await paymentService?.hasActiveSubscription()
                if hasActiveSubscription == true {
                    delegate?.onboardingChildScreenUpdate(value: nil,
                                                          description: "User has active subscription",
                                                          logAnalytics: true)
                    close()
                }
            } catch {
                delegate?.onboardingChildScreenUpdate(value: nil, 
                                                      description: "Did fail to restore purchases: \(error.localizedDescription)",
                                                      logAnalytics: true)
                handleError(error, message: "Failed to restore purchases") { [weak self] in
                    self?.restoreProducts()
                }
            }
            setViewBusy(false)
        }
    }
    
    func purchaseSelectedProduct() {
        guard selectedIndex < products.count else { return }
        
        let selectedProduct = products[selectedIndex]
        setViewBusy(true)
        Task {
            do {
                try await paymentService.purchaseProduct(selectedProduct.skProduct)
                delegate?.onboardingChildScreenUpdate(value: nil,
                                                      description: "Did purchase product: \(selectedProduct.id)",
                                                      logAnalytics: true)
                // TODO: - Finish
                //                onboardingChildScreenPerform
                close()
            } catch OnboardingPaywallError.cancelled {
                delegate?.onboardingChildScreenUpdate(value: nil, 
                                                      description: "Cancelled purchase",
                                                      logAnalytics: true)
                if shouldCloseOnPurchaseCancel {
                    close()
                }
            } catch {
                handleError(error, message: "Failed to purchase", retryAction: { [weak self] in
                    self?.purchaseSelectedProduct()
                })
                delegate?.onboardingChildScreenUpdate(value: nil,
                                                      description: "Did fail to purchase: \(error.localizedDescription)",
                                                      logAnalytics: true)
            }
            setViewBusy(false)
        }
    }
    
    func didLoadProducts() {
        self.isLoadingProducts = false
        let sections = allSections()
        self.collectionView.performBatchUpdates {
            collectionView.reloadSections(IndexSet(0..<sections.count))
        }
    }
    
    @objc func closeButtonPressed() {
        guard !isBusy else { return }
        
        delegate?.onboardingChildScreenUpdate(value: nil, 
                                              description: "Close",
                                              logAnalytics: true)
        close()
    }
    
    func close() {
        
    }
    
    @MainActor
    func handleError(_ error: Error,
                     message: String,
                     retryAction: @escaping EmptyCallback) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { [weak self] _ in
            self?.delegate?.onboardingChildScreenUpdate(value: nil, 
                                                        description: "Restore",
                                                        logAnalytics: true)
            retryAction()
        }))
        present(alert, animated: true)
    }
    
    func setViewBusy(_ isBusy: Bool) {
        self.isBusy = isBusy
        if isBusy {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        view.isUserInteractionEnabled = !isBusy
    }
}

// MARK: - Setup methods
private extension PaywallVC {
    func setup() {
        setupNavigationBar()
        setupCollectionView()
        setupBottomView()
        setupGradientView()
        loadProducts()
    }
    
    func setupNavigationBar() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeButtonPressed))
        closeButton.tintColor = .black
        navigationItem.leftBarButtonItem = closeButton
    }
    
    func setupCollectionView() {
        [PaywallHeaderCell.self,
         PaywallListSubscriptionCell.self,
         PaywallSeparatorCell.self,
         PaywallLoadingCell.self].forEach { cellType in
            collectionView.registerCellNibOfType(cellType)
        }
        
        collectionView.contentInsetAdjustmentBehavior = .never
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.clipsToBounds = false
    }
    
    func setupBottomView() {
        bottomView.delegate = self
    }
    
    func setupGradientView() {
        gradientView.gradientColors = [.white.withAlphaComponent(0.01),
                                       .white]
        gradientView.gradientDirection = .topToBottom
    }
}

// MARK: - Open methods
extension PaywallVC {
    
    enum SectionType {
        case header
        case items
        case separator
    }
    
    enum RowType {
        case header(HeaderCellConfiguration)
        case separator
        case oneTypePurchase(ListOneTypePurchaseCellConfiguration)
        case listSubscription(ListSubscriptionCellConfiguration)
        case loading
        
        var height: CGFloat {
            switch self {
            case .header, .loading:
                return 0
            case .separator:
                return 1
            case .listSubscription, .oneTypePurchase:
                return UIScreen.isIphoneSE1 ? 60 : 77
            }
        }
    }
    
    struct HeaderCellConfiguration {
        let imageURL: URL
        let title: String
        let subtitle: String
    }
    
    struct ListSubscriptionCellConfiguration {
        let product: StoreKitProduct
        let subscriptionDescription: StoreKitSubscriptionDescription
        let badgePosition: PaywallListSubscriptionCell.SavedMoneyBadgePosition
    }
    
    struct ListOneTypePurchaseCellConfiguration {
        let product: StoreKitProduct
        let badgePosition: PaywallListSubscriptionCell.SavedMoneyBadgePosition
    }
    
    func allSections() -> [SectionType] {
        var sections: [SectionType] = [.header]
        
        sections.append(.separator)
        sections.append(.items)
        return sections
    }
    
    func rowsFor(section: SectionType) -> [RowType] {
        switch section {
        case .header:
            return [.header(.mock())]
        case .separator:
            return [.separator]
        case .items:
            if isLoadingProducts {
                return [.loading]
            }

            return products.map { product in
                switch product.type {
                case .oneTimePurchase:
                    return .oneTypePurchase(.init(product: product,
                                                  badgePosition: .left))
                case .subscription(let description):
                    return .listSubscription(.init(product: product,
                                                   subscriptionDescription: description,
                                                   badgePosition: .left))
                }
            }
        }
    }
}

extension PaywallVC {
    struct Constants {
        static let defaultHeaderHeight: CGFloat = { UIScreen.isIphoneSE1 ? 180 : 280 }()
        static let sectionsSpacing: CGFloat = { UIScreen.isIphoneSE1 ? 12 :24 }()
        static let listItemsSpacing: CGFloat = { UIScreen.isIphoneSE1 ? 8 : 16 }()
    }
}

//@available(iOS 17, *)
//#Preview {
//    createPreviewVC()
//}

//import SwiftUI
//struct PaywallVCPreviews: PreviewProvider {
//    static var previews: some View {
//        UIViewControllerPreview {
//           createPreviewVC()
//        }
//        .edgesIgnoringSafeArea(.all)
//        .preferredColorScheme(.dark)
//    }
//}

func createPreviewVC() -> UIViewController {
    let paymentService = PreviewPaymentService()
    let vc = PaywallVC.instantiate(paymentService: paymentService)
    vc.productIds = ["1", "2"]
    let nav = UINavigationController(rootViewController: vc)
    
    return nav
}

final class PreviewPaymentService: OnboardingPaymentServiceProtocol {
    var canMakePayments: Bool { true }
  
    func fetchProductsWith(ids: Set<String>) async throws -> [SKProduct] {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        return SKProduct.mock(productIds: ids)
    }
    
    func restorePurchases() async throws {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
    }
    
    func purchaseProduct(_ product: SKProduct) async throws {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
//        throw NSError(domain: "com", code: 12)
    }
    
    func hasActiveSubscription() async throws -> Bool {
        false
    }
}

private extension PaywallVC.HeaderCellConfiguration {
    static func mock() -> PaywallVC.HeaderCellConfiguration {
        .init(imageURL: URL(string: "https://img.freepik.com/free-photo/painting-mountain-lake-with-mountain-background_188544-9126.jpg?size=626&ext=jpg&ga=GA1.1.1546980028.1703462400&semt=sph")!,
              title: "Do you have a question? ",
              subtitle: "Just ask it to our lawyer and get a quick and high-quality answer. ")
    }
}
