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
final class PaywallVC: BaseScreenGraphViewController {
    
     var videoPreparationService: VideoPreparationService!

     var transitionKind: ScreenTransitionKind?
     
     
    public static func instantiate(paymentService: OnboardingPaymentServiceProtocol, screen: Screen, screenData: ScreenBasicPaywall, videoPreparationService: VideoPreparationService) -> PaywallVC {
        let paywallVC = PaywallVC.nibInstance()
        paywallVC.screen = screen
        paywallVC.paymentService = paymentService
        paywallVC.videoPreparationService = videoPreparationService
        paywallVC.screenData = screenData
        paywallVC.loadViewIfNeeded()
        return paywallVC
    }
     
    private var screenData: ScreenBasicPaywall! = nil

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var bottomView: PaywallBottomView!
    @IBOutlet weak var gradientView: GradientView!
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var headerView: UIView!

    private var paymentService: OnboardingPaymentServiceProtocol!
    private var selectedIndex: Int = 0
    private var isLoadingProducts = true
    private var isBusy = true
    private var products: [StoreKitProduct] = []
    public var productIds: [String] = []
    public var style: Style = .subscriptionsList
    var shouldCloseOnPurchaseCancel = false
    
    public var dismissalHandler: (() -> ())!

    @IBOutlet private weak var backgroundContainerView: UIView!
    
    let cellConfigurator =  PaywallCellWithBorderConfigurator()

    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        let ids = screenData.subscriptions.items.compactMap({$0.subscriptionId})
        productIds = ids
        
        loadProducts()
//        add selected product to parameters
        OnboardingService.shared.eventRegistered(event: .paywallAppeared, params: [.screenID: screen.id, .screenName: screen.name])
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        OnboardingAnimation.runAnimationOfType(.tableViewCells(style: .move), in: collectionView)
        OnboardingAnimation.runAnimationOfType(.fade, in: [bottomView.additionalInfoLabelContainer, bottomView.buyButton], delay: 0.3)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
//        OnboardingService.shared.eventRegistered(event: .paywallDisappeared, params: [.screenID: screen.id, .screenName: screen.name])
    }
    
    
    func setup() {
        setupBackground()
        setupCollectionView()
        setup(navigationBar: screenData.navigationBar)
        setup(footer: screenData.footer)
        setupGradientView()
    }
    
    func setupBackground() {
        backgroundView = backgroundContainerView

        if let background = self.screenData?.styles.background {
            switch background.styles {
            case .typeBackgroundStyleColor(let value):
                backgroundContainerView.backgroundColor = value.color.hexStringToColor
            case .typeBackgroundStyleImage(let value):
                updateBackground(image: value.image)
            case .typeBackgroundStyleVideo:
                setupBackgroundFor(screenId: screen.id,
                                   using: videoPreparationService)
            }
        }
    }
    
}

extension PaywallVC {
    
    func finishWith(action: Action?) {
        DispatchQueue.main.async {[weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.onboardingScreen(strongSelf, didFinishWithScreenData: action)
        }
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
            cell.setWith(configuration: configuration, paywallData: screenData)
            if screenData.video != nil {
                let screenID = screen.id + screenData.paywallHeaderVideoKeyConstant
                cell.setupBackgroundFor(screenId: screenID, using: videoPreparationService)
            }

            return cell
        case .separator:
            let cell = collectionView.dequeueCellOfType(PaywallSeparatorCell.self, at: indexPath)
            cell.setupCellWith(divider: screenData.divider)
            return cell
        case .loading:
            let cell = collectionView.dequeueCellOfType(PaywallLoadingCell.self, at: indexPath)
            
            return cell
        case .listSubscription(let configuration):
            let index = indexPath.row
            let isSelected = selectedIndex == index
            let cell = collectionView.dequeueCellOfType(PaywallListSubscriptionCell.self, at: indexPath)
            
            let currentProduct = self.products[index]

            if let item = screenData.subscriptions.items.first(where: {$0.subscriptionId == currentProduct.id}) {
                cell.setWith(isSelected: isSelected, subscriptionItem: item, listWithStyles: screenData.subscriptions, product: currentProduct)
            }
            return cell
        case .oneTimePurchase(let configuration):
            let index = indexPath.row
            let isSelected = selectedIndex == index
            let cell = collectionView.dequeueCellOfType(PaywallListSubscriptionCell.self, at: indexPath)
            let currentProduct = self.products[index]

            if let item = screenData.subscriptions.items.first(where: {$0.subscriptionId == currentProduct.id}) {
                cell.setWith(isSelected: isSelected, subscriptionItem: item, listWithStyles: screenData.subscriptions, product: currentProduct)
            }
            
            return cell
        case .tileSubscription(let configuration):
            let index = indexPath.row
            let isSelected = selectedIndex == index
            let cell = collectionView.dequeueCellOfType(PaywallTileSubscriptionCell.self, at: indexPath)

            let currentProduct = self.products[index]

            if let item = screenData.subscriptions.items.first(where: {$0.subscriptionId == currentProduct.id}) {
                cell.setWith(configuration: configuration, isSelected: isSelected, subscriptionItem: item, listWithStyles: screenData.subscriptions, product: currentProduct)
            }
            
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
        case .listSubscription, .oneTimePurchase, .tileSubscription:
            let index = indexPath.row
            if selectedIndex != index {
                var indexPathsToReload = [indexPath]
                indexPathsToReload.append(IndexPath(row: selectedIndex, section: indexPath.section))
                selectedIndex = index
                reloadCellsAt(indexPaths: indexPathsToReload)
                let currentProduct = self.products[selectedIndex]
                bottomView.setupPaymentDetailsLabel(content: currentProduct)

                OnboardingService.shared.eventRegistered(event: .productSelected, params: [.screenID: screen.id, .screenName: screen.name, .selectedProductId: currentProduct.id])
                OnboardingService.shared.eventRegistered(event: .userUpdatedValue, params: [.screenID: screen.id, .screenName: screen.name, .selectedProductId: currentProduct.id])
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


// MARK: - PaywallBottomViewDelegate
extension PaywallVC: PaywallBottomViewDelegate {
    
    func paywallBottomViewBuyButtonPressed(_ paywallBottomView: PaywallBottomView) {
        purchaseSelectedProduct()
    }
  
    func paywallBottomViewPPButtonPressed(_ paywallBottomView: PaywallBottomView, url: String) {
        OnboardingService.shared.eventRegistered(event: .ppButtonPressed, params: [.screenID: screen.id, .screenName: screen.name, .url: url])

        if let url = URL.init(string: url) {
            showSafariWith(url: url)
        }
    }
    
    func paywallBottomViewTACButtonPressed(_ paywallBottomView: PaywallBottomView, url: String) {
        OnboardingService.shared.eventRegistered(event: .tcButtonPressed, params: [.screenID: screen.id, .screenName: screen.name, .url: url])

        if let url = URL.init(string: url) {
            showSafariWith(url: url)
        }
    }
    
    func paywallBottomViewRestoreButtonPressed(_ paywallBottomView: PaywallBottomView) {
//        delegate?.onboardingChildScreenUpdate(value: nil,
//                                              description: "Restore",
//                                              logAnalytics: true)
        restoreProducts()
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
            height = collectionView.bounds.height - calculateHeaderSize(in: sections) - sectionsSpacing
        case .tileSubscription:
            return Constants.subscriptionTileItemSize
        case .listSubscription:
//            let item = screenData.subscriptions.items[indexPath.row]
            let currentProduct = self.products[indexPath.row]
            
            if let item = screenData.subscriptions.items.first(where: {$0.subscriptionId == currentProduct.id}) {
                height =  cellConfigurator.calculateHeightFor(item: item, product: currentProduct, screenData: screenData, containerWidth: collectionView.bounds.width)
            }
        case .separator:
            height = PaywallSeparatorCell.calculateHeightFor(divider: screenData.divider)

        default:
            height = row.height
        }
        height = max(0, height)
        return .init(width: collectionView.bounds.width, height: height)
    }
    
    func calculateHeaderSize(in sections: [SectionType]) -> CGFloat {
        var contentSize: CGFloat = 0
        for section in sections {
            switch section {
            case .header, .separator:
                contentSize += Constants.sectionsSpacing
            case .items:
                switch style {
                case .subscriptionsList:
                    let numberOfItems: Int
                    if isLoadingProducts {
                        numberOfItems = productIds.count
                    } else {
                        let items = rowsFor(section: section)
                        numberOfItems = items.count
                    }
                    
                    var itemsHeight: CGFloat = 0.0
                    
                    for (index, currentProduct) in  self.products.enumerated() {
                        if let item = screenData.subscriptions.items.first(where: {$0.subscriptionId == currentProduct.id}) {
                            itemsHeight += cellConfigurator.calculateHeightFor(item: item, product: currentProduct, screenData: screenData, containerWidth: collectionView.bounds.width)
                        }
                    }
                    
                    itemsHeight += PaywallSeparatorCell.calculateHeightFor(divider: screenData.divider)
                    if screenData.divider != nil {
                        itemsHeight +=  PaywallSeparatorCell.calculateHeightFor(divider: screenData.divider)
                    }

                    let spacingHeight = CGFloat(numberOfItems - 1) * Constants.listItemsSpacing
                    contentSize += (itemsHeight + spacingHeight)
                case .subscriptionsTiles:
                    var itemsHeight: CGFloat = 0.0

                    if screenData.divider != nil {
                        itemsHeight +=  PaywallSeparatorCell.calculateHeightFor(divider: screenData.divider)
                    }
                    contentSize += Constants.subscriptionTileItemSize.height + itemsHeight
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
            switch style {
            case .subscriptionsList:
                return .zero
            case .subscriptionsTiles:
                let containerWidth = collectionView.bounds.width
                let items = rowsFor(section: section)
                let tilesWidth = CGFloat(items.count) * Constants.subscriptionTileItemSize.width
                let tilesSpacing: CGFloat = 20
                let sideSpace = containerWidth - tilesWidth - tilesSpacing
                return .init(top: 0, left: sideSpace / 2, bottom: 0, right: sideSpace / 2)
            }
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
//        delegate?.onboardingChildScreenUpdate(value: nil,
//                                              description: "Will load products",
//                                              logAnalytics: true)

        Task {
            do {
                let productIds = self.productIds
                let skProducts = try await paymentService.fetchProductsWith(ids: Set(productIds))
//                delegate?.onboardingChildScreenUpdate(value: nil,
//                                                      description: "Did load products: \(products.map { $0.productIdentifier })",
//                                                      logAnalytics: true)
                let products = skProducts
                    .compactMap( { StoreKitProduct(skProduct: $0) })
                    .sorted(by: { lhs, rhs in
                        guard let lhsIndex = productIds.firstIndex(where: { $0 == lhs.id }),
                              let rhsIndex = productIds.firstIndex(where: { $0 == rhs.id }) else {
                            return false
                        }
                        
                        return lhsIndex < rhsIndex
                    })
                
                didLoadProducts(products)
            } catch {
//                delegate?.onboardingChildScreenUpdate(value: nil,
//                                                      description: "Did fail to load products: \(error.localizedDescription)",
//                                                      logAnalytics: true)
                didFailToLoadProductsWith(error: error)
            }
        }
    }
    
    func didLoadProducts(_ products: [StoreKitProduct]) {
        self.products = products
        if let item = screenData.subscriptions.items.first(where: {$0.isSelected}) {
            for (index, product) in self.products.enumerated() {
                if product.id == item.subscriptionId {
                    selectedIndex = index
                    print("selectedIndex \(selectedIndex)")
                    break
                }
            }
        }
        
        self.isLoadingProducts = false
        
//        DispatchQueue.main.async {
//            self.setViewForLoadedProducts()
//        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.setViewForLoadedProducts()
                }
    }
    
    func setViewForLoadedProducts() {
        if products.count - 1 >= selectedIndex {
            let currentProduct = products[selectedIndex]
            bottomView.setupPaymentDetailsLabel(content: currentProduct)
        }
        collectionView.reloadData()
    }
    
    func didFailToLoadProductsWith(error: Error) {
        handleError(error, message: "Something went wrong") { [weak self] in
            self?.loadProducts()
        }
    }
    
    func restoreProducts() {
        setViewBusy(true)
        OnboardingService.shared.eventRegistered(event: .restorePurchaseButtonPressed, params: [.screenID: screen.id, .screenName: screen.name])

        Task {
            do {
                try await paymentService?.restorePurchases()
                let hasActiveSubscription = try await paymentService?.hasActiveSubscription()
                
                OnboardingService.shared.eventRegistered(event: .productRestored, params: [.hasActiveSubscription: hasActiveSubscription ?? false, .screenName: screen.name, .screenID: screen.id,])

                if hasActiveSubscription == true {
                    
//                    OnboardingService.shared.eventRegistered(event: .paywallAppeared, params: [.screenID: screen.id, .screenName: screen.name])

                    close()
                }
            } catch {
                OnboardingService.shared.eventRegistered(event: .productRestored, params: [.error: error.localizedDescription, .screenName: screen.name, .screenID: screen.id,])

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
        OnboardingService.shared.eventRegistered(event: .purchaseButtonPressed, params: [.screenID: screen.id, .screenName: screen.name, .selectedProductId: selectedProduct.id])

        setViewBusy(true)
        Task {
            do {
                try await paymentService.purchaseProduct(selectedProduct.skProduct)
                Task {
                    if let transaction = try await paymentService.activeSubscriptionReceipt() {
                        OnboardingService.shared.eventRegistered(event: .productPurchased, params: [.screenID: screen.id, .screenName: screen.name, .productId: selectedProduct.id, .transactionId : transaction.originalTransactionId])
                        sendReceiptInfo()
                    }
                }
                
                self.value = selectedProduct.id
                
                finishWith(action: screenData.footer.purchase?.action)
            } catch OnboardingPaywallError.cancelled {
                OnboardingService.shared.eventRegistered(event: .purchaseCanceled, params: [.screenID: screen.id, .screenName: screen.name, .productId: selectedProduct.id])

                if shouldCloseOnPurchaseCancel {
                    close()
                }
            } catch {
                handleError(error, message: "Failed to purchase", retryAction: { [weak self] in
                    self?.purchaseSelectedProduct()
                })

                OnboardingService.shared.eventRegistered(event: .purchaseFailed, params: [.screenID: screen.id, .screenName: screen.name, .productId: selectedProduct.id, .error: error.localizedDescription])

            }
            setViewBusy(false)
        }
    }
    
    func sendReceiptInfo() {
        Task {
            do {
                if let receipt = try await self.paymentService.activeSubscriptionReceipt() {
                        let purchase = PurchaseInfo.init(integrationType: .Amplitude, userId: "", transactionId: receipt.originalTransactionId, amount: 20.0, currency: "usd")
                    let projectId = "2370dbee-0b62-49ea-8ccb-ef675c6dd1f9"

                        AttributionStorageManager.sendPurchase(projectId: projectId, transactionId: receipt.originalTransactionId, purchaseInfo: purchase)
                } else {
                    // Чек не найден, но и ошибки не было
                    print("Активный чек подписки не найден")
                }
            } catch {
                // Произошла ошибка при получении чека
                print("Ошибка при получении чека: \(error)")
            }
        }
    }
    
    func sendToServer(transactionId: String) {
        OnboardingLoadingService.sendPaymentInfo(transactionId: transactionId, projectId: "") { result in

        }
    }
    
    @objc func closeButtonPressed() {
//        guard !isBusy else { return }
                
        OnboardingService.shared.eventRegistered(event: .paywallCloseButtonPressed, params: [.screenID: screen.id, .screenName: screen.name])

        finishWith(action: screenData.navigationBar.close?.action)
    }
    
    func close() {
        finishWith(action: screenData.footer.purchase?.action)
    }
    
    @MainActor
    func handleError(_ error: Error,
                     message: String,
                     retryAction: @escaping EmptyCallback) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in
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
    
    func setup(footer: PaywallFooter) {
        bottomView.setup(footer: footer)
        bottomView.delegate = self
    }

    func setup(navigationBar: PaywallNavigationBar) {
        guard let close = navigationBar.close else {
            closeButton.isHidden = true
            return
        }
    
        closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        closeButton.tintColor = close.styles.backgroundColor?.hexStringToColor ?? .black
        
        var horizontalConstraint = closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16)
   
        if let alignment = navigationBar.styles.closeHorizontalAlignment {
            switch alignment {
            case ._left:
                horizontalConstraint = closeButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16)
            case ._right:
                break
            }
        }
        NSLayoutConstraint.activate([horizontalConstraint])

        switch navigationBar.styles.closeAppearance {
        case .visibleaftertimer:
            if let time = navigationBar.styles.closeVisibleAfterTimerValue {
                closeButton.isHidden = true

                DispatchQueue.main.asyncAfter(deadline: .now() + time) {[weak self]  in
                    self?.closeButton.isHidden = false
                }
            }
        default:
            break
        }
    }
    
    func setupCollectionView() {
        [PaywallHeaderCell.self,
         PaywallListSubscriptionCell.self,
         PaywallSeparatorCell.self,
         PaywallLoadingCell.self,
         PaywallTileSubscriptionCell.self].forEach { cellType in
            collectionView.registerCellNibOfType(cellType)
        }
        
        collectionView.contentInsetAdjustmentBehavior = .never
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.clipsToBounds = false
    }
    
    func setupGradientView() {
//        gradientView.gradientColors = [.white.withAlphaComponent(0.01),
//                                       .white]
//        gradientView.gradientDirection = .topToBottom
    }
    
}

// MARK: - Open methods
extension PaywallVC {
    
    public enum Style {
        case subscriptionsList
        case subscriptionsTiles
    }
    
    enum SectionType {
        case header
        case items
        case separator
    }
    
    enum RowType {
        case header(HeaderCellConfiguration)
        case separator
        case oneTimePurchase(ListOneTimePurchaseCellConfiguration)
        case listSubscription(ListSubscriptionCellConfiguration)
        case tileSubscription(TileSubscriptionCellConfiguration)
        case loading
        
        var height: CGFloat {
            switch self {
            case .header, .loading:
                return 0
            case .separator:
                return 1
            case .listSubscription, .oneTimePurchase:
                return Constants.subscriptionListItemHeight
            case .tileSubscription:
                return Constants.subscriptionTileItemSize.height
            }
        }
    }
    
    struct HeaderCellConfiguration {
        let imageURL: URL
        let style: PaywallHeaderCell.Style
    }
    
    struct ListSubscriptionCellConfiguration {
        let product: StoreKitProduct
        let subscriptionDescription: StoreKitSubscriptionDescription
        let badgePosition: PaywallListSubscriptionCell.SavedMoneyBadgePosition
    }
    
    struct ListOneTimePurchaseCellConfiguration {
        let product: StoreKitProduct
        let badgePosition: PaywallListSubscriptionCell.SavedMoneyBadgePosition
    }
    
    struct TileSubscriptionCellConfiguration {
        let product: StoreKitProduct
        let subscriptionDescription: StoreKitSubscriptionDescription
        let badgePosition: PaywallTileSubscriptionCell.SavedMoneyBadgePosition
        let checkmarkPosition: PaywallTileSubscriptionCell.CheckmarkPosition
    }
    
    func allSections() -> [SectionType] {
        var sections: [SectionType] = [.header]
        if screenData.divider != nil {
            sections.append(.separator)
        }
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

            switch style {
            case .subscriptionsList:
                
                return products.map { product in
                    switch product.type {
                    case .oneTimePurchase:
                        return .oneTimePurchase(.init(product: product,
                                                      badgePosition: .left))
                    case .subscription(let description):
                        return .listSubscription(.init(product: product,
                                                       subscriptionDescription: description,
                                                       badgePosition: .left))
                    }
                }
            case .subscriptionsTiles:
                return products.compactMap { product in
                    switch product.type {
                    case .oneTimePurchase:
                        return .oneTimePurchase(.init(product: product,
                                                      badgePosition: .left))
                    case .subscription(let description):
                        return .tileSubscription(.init(product: product,
                                                       subscriptionDescription: description,
                                                       badgePosition: .right,
                                                       checkmarkPosition: .left))
                    }
                }
                
//                return products.compactMap { product in
//                    guard case .subscription(let description) = product.type else { return nil }
//                    
//                    return .tileSubscription(.init(product: product,
//                                                   subscriptionDescription: description,
//                                                   badgePosition: .right,
//                                                   checkmarkPosition: .left))
//                }
            }
        }
    }
}

extension PaywallVC {
    
    struct Constants {
        static let defaultHeaderHeight: CGFloat = { UIScreen.isIphoneSE1 ? 180 : 280 }()
        static let sectionsSpacing: CGFloat = { UIScreen.isIphoneSE1 ? 0 : 0 }()
        static let listItemsSpacing: CGFloat = { UIScreen.isIphoneSE1 ? 8 : 16 }()
        
        
//        static let sectionsSpacing: CGFloat = { 0 }()
//
//        static let listItemsSpacing: CGFloat = { 0 }()

        
//        static let subscriptionListItemHeight: CGFloat = { UIScreen.isIphoneSE1 ? 60 : 77 }()
        
        static let subscriptionListItemHeight: CGFloat = { UIScreen.isIphoneSE1 ? 60 : 120 }()

        static let subscriptionTileItemSize: CGSize = {
            UIScreen.isIphoneSE1 ? CGSize(width: 120, height: 120) : CGSize(width: 140, height: 150)
        }()
    }
    
}

private extension PaywallVC.HeaderCellConfiguration {
    static func mock() -> PaywallVC.HeaderCellConfiguration {
        .init(imageURL: URL(string: "https://img.freepik.com/free-photo/painting-mountain-lake-with-mountain-background_188544-9126.jpg?size=626&ext=jpg&ga=GA1.1.1546980028.1703462400&semt=sph")!,
//              style: .titleSubtitle(title: "Do you have a question? ",
//                                    subtitle: "Just ask it to our lawyer and get a quick and high-quality answer. ")
              style: .titleBulletsList(title: "Do you have a question? ",
                                    bulletsList: ["Just ask it to our lawyer",
                                                  "Just ask it to our",
                                                  "Just ask it to"])
        )
    }
}


final class PaywallCellWithBorderConfigurator: CellConfigurator {
    var cellLeading: CGFloat = 24
    var cellTrailing: CGFloat = 24
    var cellTop: CGFloat = 24
    var cellBottom: CGFloat = 24
    var labelHorizontalSpacing: CGFloat = 4
    
    func calculateHeightFor(item: ItemTypeSubscription, product: StoreKitProduct?, screenData: ScreenBasicPaywall, containerWidth: CGFloat) -> CGFloat {
        ///cell size
        cellTrailing = 16 + (screenData.subscriptions.box.styles.paddingRight ?? 0)
        cellLeading = 16 + (screenData.subscriptions.box.styles.paddingLeft ?? 0)
        cellTop = 16 + (screenData.subscriptions.box.styles.paddingTop ?? 0)
        cellBottom = 16 + (screenData.subscriptions.box.styles.paddingBottom ?? 0)

        let containerWidthWithoutPaddings: CGFloat = containerWidth - cellTrailing - cellLeading
        allItemsHorizontalStackViewSpacing = 0
        
        ///cell content size
        containerLeading = screenData.subscriptions.styles.paddingLeft ?? 16
        containerTrailing = screenData.subscriptions.styles.paddingRight ?? 16
        containerTop = screenData.subscriptions.styles.paddingTop ?? 16
        containerBottom = screenData.subscriptions.styles.paddingBottom ?? 16
        
        /// Add gaps between rows and columns
        labelsVerticalStackViewSpacing = item.styles.columnVerticalPadding ?? 4
        labelHorizontalSpacing = item.styles.columnHorizontalPadding ?? 4
        if item.isOneColumn() {
            labelHorizontalSpacing = 0.0
        }
        
        // Calculate effective width for labels heights calculation
        var labelWidth = containerWidthWithoutPaddings - containerLeading - containerTrailing - labelHorizontalSpacing
        
        if !isImageHiddenFor(item: item) {
            labelWidth -= (imageWidth + allItemsHorizontalStackViewSpacing)
        } else {
            self.imageWidth = 0
            self.imageHeigh = 0
        }
        
        /// Add checkbox width
        if !isCheckboxHiddenFor(list: screenData.subscriptions) {
            let checkBoxContainer = (item.checkBox.styles.width ?? 24.0) + (item.checkBox.box.styles.paddingLeft ?? 0.0) + (item.checkBox.box.styles.paddingRight ?? 0.0)
            labelWidth = labelWidth - checkBoxContainer
        }
        
        //Calculate labels height
        var totalLabelsBlockHeight = 0.0
        var subtitleHeight: CGFloat = 0.0
        
        let titleText: Text
        let subtitleText: Text
        
        ///Calculate size of columns
        let leftColumnSize = (item.styles.leftLabelColumnWidthPercentage ?? 60)/100.00
        let rightColumnSize = 1 - leftColumnSize
        
        var leftColumnSizeValue = (labelWidth - labelHorizontalSpacing/2) * leftColumnSize
        var rightColumnSizeValue = (labelWidth - labelHorizontalSpacing/2) * rightColumnSize
        
        /// If one column is empty then use all container width
        if item.isLeftColumnEmpty() {
            rightColumnSizeValue = labelWidth
        }
        
        if item.isRightColumnEmpty() {
            leftColumnSizeValue = labelWidth
        }

        ///Left column height
        let leftColumnHeight = item.leftLabelTop.textHeightBy(textWidth: leftColumnSizeValue, product: product) +  item.leftLabelBottom.textHeightBy(textWidth: leftColumnSizeValue, product: product)
        ///Right column height
        let rightColumnHeight = item.rightLabelTop.textHeightBy(textWidth: rightColumnSizeValue, product: product) +  item.rightLabelBottom.textHeightBy(textWidth: rightColumnSizeValue, product: product)

        let floatMaxHeightColumnWidth: Double
        if leftColumnHeight >= rightColumnHeight {
            titleText = item.leftLabelTop
            subtitleText  = item.leftLabelBottom
            floatMaxHeightColumnWidth = leftColumnSizeValue
        } else {
            titleText = item.rightLabelTop
            subtitleText  = item.rightLabelBottom
            floatMaxHeightColumnWidth = rightColumnSizeValue
        }

        let titleHeight = titleText.textHeightBy(textWidth: floatMaxHeightColumnWidth, product: product)

        totalLabelsBlockHeight += titleHeight > 0.0 ? titleHeight : 0
        
        subtitleHeight = subtitleText.textHeightBy(textWidth: floatMaxHeightColumnWidth, product: product)
        totalLabelsBlockHeight += subtitleHeight > 0.0 ? subtitleHeight : 0
                  
        //Add gap between labels if there are 2 labels
        if item.isTwoLabelInAnyColumn() {
            totalLabelsBlockHeight += labelsVerticalStackViewSpacing
        }
        
        //Get max elemets height for cell height
        var maxHeight = totalLabelsBlockHeight > imageHeigh ? totalLabelsBlockHeight : imageHeigh
        
        maxHeight = maxHeight > checkboxSize ? maxHeight : checkboxSize
        
        let cellHeight = maxHeight + containerTop + containerBottom
        
        return cellHeight
    }
    
    func isCheckboxHiddenFor(list: SubscriptionList) -> Bool {
        switch list.itemType {
        case .checkboxLabels, .labelsCheckbox:
            return false
        default:
            return true
        }
    }
    
    func isImageHiddenFor(item: ItemTypeSubscription) -> Bool {
        return true
    }
}

extension ItemTypeSubscription {
    
    func isTwoLabelInAnyColumn() -> Bool {
        let is2NonEmptyLabelsLeftColumn = !self.leftLabelTop.textByLocale().isEmpty && !self.leftLabelBottom.textByLocale().isEmpty
        let is2NonEmptyLabelsRightColumn = !self.rightLabelTop.textByLocale().isEmpty && !self.rightLabelBottom.textByLocale().isEmpty
        if is2NonEmptyLabelsLeftColumn || is2NonEmptyLabelsRightColumn {
            return true
        } else {
            return false
        }
    }
    
    func isLeftColumnEmpty() -> Bool {
        let isEmpty = self.leftLabelTop.textByLocale().isEmpty && self.leftLabelBottom.textByLocale().isEmpty
        return isEmpty
    }
    
    func isRightColumnEmpty() -> Bool {
        let isEmpty = self.rightLabelTop.textByLocale().isEmpty && self.rightLabelBottom.textByLocale().isEmpty
        return isEmpty
    }
    
    func isOneColumn() -> Bool {
        if isLeftColumnEmpty() || isRightColumnEmpty() {
            return true
        }
        return false
    }
    
}
