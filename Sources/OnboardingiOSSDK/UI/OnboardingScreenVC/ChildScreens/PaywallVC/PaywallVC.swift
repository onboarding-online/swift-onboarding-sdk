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
public final class PaywallVC: BaseScreenGraphViewController {
    
    public static func instantiate(paymentService: OnboardingPaymentServiceProtocol, screen: Screen, screenData: ScreenBasicPaywall, videoPreparationService: VideoPreparationService) -> PaywallVC {
        let paywallVC = PaywallVC.nibInstance()
        paywallVC.screen = screen
        paywallVC.paymentService = paymentService
        paywallVC.videoPreparationService = videoPreparationService
        paywallVC.screenData = screenData
        paywallVC.loadViewIfNeeded()
        return paywallVC
    }
     
    var videoPreparationService: VideoPreparationService!
    var transitionKind: ScreenTransitionKind?
    
    public var productIds: [String] = []
    public var style: Style = .subscriptionsList
    var shouldCloseOnPurchaseCancel = false
        
    public var closePaywallHandler: ((PaywallVC) -> ())? = nil
    public var purchaseHandler: ((PaywallVC, OnboardingPaymentReceipt?) -> ())? = nil

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var bottomView: PaywallBottomView!
    
    @IBOutlet weak var closeButton: UIButton!

    var restoreButton: UIButton!

    @IBOutlet weak var headerView: UIView!
    @IBOutlet private weak var backgroundContainerView: UIView!

    private var paymentService: OnboardingPaymentServiceProtocol!
    private var selectedIndex: Int = 0
    private var isLoadingProducts = true
    private var isBusy = true
    private var products: [StoreKitProduct] = []
    private var screenData: ScreenBasicPaywall! = nil

    let cellConfigurator =  PaywallCellWithBorderConfigurator()
    
    private var constants: PaywallCollectionConstants!

    public override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        setupSubscriptionType()
        setupProducts()
        baseAppearanceSetup()
        loadProducts()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setup(navigationBar: screenData.navigationBar)
        OnboardingService.shared.eventRegistered(event: .paywallAppeared, params: [.screenID: screen.id, .screenName: screen.name])

        navigationController?.isNavigationBarHidden = true
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        OnboardingService.shared.eventRegistered(event: .paywallDisappeared, params: [.screenID: screen.id, .screenName: screen.name])
    }
    
}

extension PaywallVC {
    
    func baseAppearanceSetup() {
        constants = PaywallCollectionConstants.init()
    
        constants.leadingConstraint = 16 +  (screenData.subscriptions.box.styles.paddingLeft ?? 0)
        constants.trailingConstraint = 16 + (screenData.subscriptions.box.styles.paddingRight ?? 0)
        
        bottomView.currencyFormatKind = screenData.currencyFormat
       
        activityIndicator.color = screenData.loader?.styles.color?.hexStringToColor ?? .gray
    }
    
    func setupProducts() {
        let ids = screenData.subscriptions.items.compactMap({$0.subscriptionId})
        productIds = ids
    }
    
    func setupSubscriptionType() {
        switch screenData.subscriptions.subscriptionViewKind {
        case .vertical:
            style = .subscriptionsList
        case .horizontal:
            style = .subscriptionsTiles
        default:
            style = .subscriptionsList
        }
    }
    
    func setupTopConstraint() {
        collectionView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
    }
    
    func loadProducts() {
        print( "Will load products")
        if var skProducts = paymentService.cashedProductsWith(ids:  Set(productIds)),  productIds.count == skProducts.count {
            skProducts = skProducts.compactMap({ product in
                if (productIds.firstIndex(where: {$0 == product.productIdentifier}) != nil) {
                    return product
                } else {
                    return nil
                }
            })
            
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
            return
        }

        Task {
            do {
                let productIds = self.productIds
                var skProducts = try await paymentService.fetchProductsWith(ids: Set(productIds))
                skProducts = skProducts.compactMap({ product in
                    if (productIds.firstIndex(where: {$0 == product.productIdentifier}) != nil) {
                        return product
                    } else {
                        return nil
                    }
                })

                let products = skProducts
                    .compactMap( { StoreKitProduct(skProduct: $0) })
                    .sorted(by: { lhs, rhs in
                        guard let lhsIndex = productIds.firstIndex(where: { $0 == lhs.id }),
                              let rhsIndex = productIds.firstIndex(where: { $0 == rhs.id }) else {
                            return false
                        }
                        
                        return lhsIndex < rhsIndex
                    })
                
                print( "loaded prodcucts - \(products)  ids \(productIds)")

                didLoadProducts(products)
            } catch {
                didFailToLoadProductsWith(error: error)
            }
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
        
        let rows =  rowsFor(section: section)
        print("section \(section)  rows \(rows)")
        print("products \(self.products.count)")

        return rows.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = allSections()[indexPath.section]
        let row = rowsFor(section: section)[indexPath.row]
                
        switch row {
        case .header:
            let cell = collectionView.dequeueCellOfType(PaywallHeaderCell.self, at: indexPath)
            cell.setWith(paywallData: screenData)
            if screenData.media?.kind == .video  {
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
        case .listSubscription, .oneTimePurchase:
            if self.products.isEmpty {
                let index = indexPath.row
                let isSelected = selectedIndex == index
                let cell = collectionView.dequeueCellOfType(PaywallListSubscriptionCell.self, at: indexPath)
                cell.currencyFormatKind =  screenData.currencyFormat
                let item = screenData.subscriptions.items[index]

                cell.setWith(isSelected: isSelected, subscriptionItem: item, listWithStyles: screenData.subscriptions)

                return cell
            } else {
                let index = indexPath.row
                let isSelected = selectedIndex == index
                let cell = collectionView.dequeueCellOfType(PaywallListSubscriptionCell.self, at: indexPath)
                cell.currencyFormatKind =  screenData.currencyFormat
                let currentProduct = self.products[index]

                if let item = screenData.subscriptions.items.first(where: {$0.subscriptionId == currentProduct.id}) {
                    cell.setWith(isSelected: isSelected, subscriptionItem: item, listWithStyles: screenData.subscriptions, product: currentProduct)
                }
                return cell
            }
        case .tileSubscription:
            let index = indexPath.row
            let isSelected = selectedIndex == index
            let cell = collectionView.dequeueCellOfType(PaywallTileSubscriptionCell.self, at: indexPath)
            cell.currencyFormatKind =  screenData.currencyFormat

            let currentProduct = self.products[index]

            if let item = itemFor(product: currentProduct) {
                cell.setWith(isSelected: isSelected, subscriptionItem: item, listWithStyles: screenData.subscriptions, product: currentProduct)
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
        case .header, .separator, .loading:
            return
        case .listSubscription, .oneTimePurchase, .tileSubscription:
            let index = indexPath.row
            
            if self.products.isEmpty {
                var indexPathsToReload = [indexPath]
                indexPathsToReload.append(IndexPath(row: selectedIndex, section: indexPath.section))
                selectedIndex = index
                reloadCellsAt(indexPaths: indexPathsToReload)
            } else {
                if selectedIndex != index{
                    var indexPathsToReload = [indexPath]
                    indexPathsToReload.append(IndexPath(row: selectedIndex, section: indexPath.section))
                    selectedIndex = index
                    reloadCellsAt(indexPaths: indexPathsToReload)
                    let currentProduct = self.products[selectedIndex]
                    
                    self.value = currentProduct.id

                    bottomView.setupPaymentDetailsLabel(content: currentProduct, currencyFormat: screenData.currencyFormat)

                    OnboardingService.shared.eventRegistered(event: .productSelected, params: [.screenID: screen.id, .screenName: screen.name, .selectedProductId: currentProduct.id])
                    OnboardingService.shared.eventRegistered(event: .userUpdatedValue, params: [.screenID: screen.id, .screenName: screen.name, .selectedProductId: currentProduct.id])
                }
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
            height = collectionView.bounds.height - calculateHeaderSize(in: sections) - sectionsSpacing
        case .tileSubscription:
            
            return calculateItemCellSize()
//            return Constants.subscriptionTileItemSize
        case .listSubscription, .oneTimePurchase:
            if self.products.isEmpty {
                let item = screenData.subscriptions.items[indexPath.row]
                
                height = cellConfigurator.calculateHeightFor(item: item, product: nil, screenData: screenData, containerWidth: collectionView.bounds.width, currencyFormat: screenData.currencyFormat)
                
            } else {
                let currentProduct = self.products[indexPath.row]
                
                if let item = itemFor(product: currentProduct) {
                    height =  cellConfigurator.calculateHeightFor(item: item, product: currentProduct, screenData: screenData, containerWidth: collectionView.bounds.width, currencyFormat: screenData.currencyFormat)
                } else {
                    height = max(40, height)
                    print("row height \(height)")
                }
            }

        case .separator:
            height = PaywallSeparatorCell.calculateHeightFor(divider: screenData.divider)

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
                    
                    if screenData.divider != nil {
                        itemsHeight +=  PaywallSeparatorCell.calculateHeightFor(divider: screenData.divider)
                    }
                    
                    if products.isEmpty {
                        for item in  self.screenData.subscriptions.items {
                            itemsHeight += cellConfigurator.calculateHeightFor(item: item, product: nil, screenData: screenData, containerWidth: collectionView.bounds.width, currencyFormat: screenData.currencyFormat)
                        }
                    } else {
                        for product in  self.products {
                            if let item = itemFor(product: product) {
                                itemsHeight += cellConfigurator.calculateHeightFor(item: item, product: product, screenData: screenData, containerWidth: collectionView.bounds.width, currencyFormat: screenData.currencyFormat)
                            }
                        }
                    }
                    
                    let spacingHeight = CGFloat(numberOfItems - 1) * Constants.listItemsSpacing
                    contentSize += (itemsHeight + spacingHeight)
                case .subscriptionsTiles:
                    var itemsHeight: CGFloat = 0.0
                   
                    if screenData.divider != nil {
                        itemsHeight +=  PaywallSeparatorCell.calculateHeightFor(divider: screenData.divider)
                    }

                    contentSize += calculateItemCellSize().height + itemsHeight
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
                return .init(top: 0, left: constants.leadingConstraint, bottom: 0, right: constants.trailingConstraint)
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }
    
}

// MARK: - Private methods
private extension PaywallVC {
    
    func itemFor(product: StoreKitProduct) -> ItemTypeSubscription? {
        let item = screenData.subscriptions.items.first(where: {$0.subscriptionId == product.skProduct.productIdentifier})
        return item
    }
    
    private var ppURL: URL {
        URL(string: "https://google.com")! // TODO: - Set PP URL
    }
    private var tacURL: URL {
        URL(string: "https://google.com")! // TODO: - Set TAC URL
    }
    
    func didLoadProducts(_ products: [StoreKitProduct]) {
        self.products = products
        if let item = screenData.subscriptions.items.first(where: {$0.isSelected}) {
            for (index, product) in self.products.enumerated() {
                if product.id == item.subscriptionId {
                    selectedIndex = index
                    break
                }
            }
        }

        self.isLoadingProducts = false
        
        DispatchQueue.main.async {
            self.setViewForLoadedProducts()
        }
    }
    
    func setViewForLoadedProducts() {
        setupCollectionView()
        setup(footer: screenData.footer)
        
        if products.count - 1 >= selectedIndex {
            let currentProduct = products[selectedIndex]
            bottomView.setupPaymentDetailsLabel(content: currentProduct, currencyFormat: screenData.currencyFormat)
        }

        if screenData.animationEnabled {
            OnboardingAnimation.runAnimationOfType(.tableViewCells(style: .fade), in: collectionView)
            OnboardingAnimation.runAnimationOfType(.fade, in: [bottomView.additionalInfoLabelContainer, bottomView.buyButton], delay: 0.3)
        }
       
//        collectionView.reloadData()
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
        guard products.count != 0 else {
            finishWith(action: screenData.footer.purchase?.action)
            return
        }
        
        guard selectedIndex < products.count else {
            return
        }
        
        let selectedProduct = products[selectedIndex]
        OnboardingService.shared.eventRegistered(event: .purchaseButtonPressed, params: [.screenID: screen.id, .screenName: screen.name, .selectedProductId: selectedProduct.id])
        self.value = selectedProduct.id
        
        setViewBusy(true)
        Task {
            do {
                try await paymentService.purchaseProduct(selectedProduct.skProduct)
                
                sendReceiptInfo(product: selectedProduct)
                self.value = selectedProduct.id
            } catch OnboardingPaywallError.cancelled {
                setViewBusy(false)
                OnboardingService.shared.eventRegistered(event: .purchaseCanceled, params: [.screenID: screen.id, .screenName: screen.name, .productId: selectedProduct.id])

                if shouldCloseOnPurchaseCancel {
                    close()
                }
            } catch {
                setViewBusy(false)
                handleError(error, message: "Failed to purchase", retryAction: { [weak self] in
                    self?.purchaseSelectedProduct()
                })

                OnboardingService.shared.eventRegistered(event: .purchaseFailed, params: [.screenID: screen.id, .screenName: screen.name, .productId: selectedProduct.id, .error: error.localizedDescription])

            }
        }
    }
    
    func sendReceiptInfo(product: StoreKitProduct) {
        Task {
            do {
                let projectId = OnboardingService.shared.projectId

                if product.type == .oneTimePurchase {
                    if let receipt = try await paymentService.lastPurchaseReceipts() {

//                        print("[trnsaction_id]-> \(receipt.originalTransactionId)")
                        let purchase = PurchaseInfo.init(integrationType: .Amplitude, userId: "", transactionId: receipt.originalTransactionId, amount: 20.0, currency: "usd")
                        
                        OnboardingService.shared.eventRegistered(event: .productPurchased, params: [.screenID: screen.id, .screenName: screen.name, .productId: product.id, .transactionId : receipt.originalTransactionId, .paymentsInfo: receipt])
                    
                        OnboardingService.shared.sendIntegrationsDetails(projectId: projectId) { error in
                            
                        }
                        
                        OnboardingService.shared.sendPurchase(projectId: projectId, transactionId: receipt.originalTransactionId, purchaseInfo: purchase)

                        closeScreenAfterPurchase(receipt: receipt)
//                        setViewBusy(false)
//                        finishWith(action: screenData.footer.purchase?.action)

                    } else {
                        closeScreenAfterPurchase(receipt: nil)
//                        setViewBusy(false)
//                        finishWith(action: screenData.footer.purchase?.action)
                    }
                } else {
                    if let receipt = try await paymentService.activeSubscriptionReceipt() {
                        

                        DispatchQueue.main.async {[weak self] in
//                            print("[trnsaction_id]-> \(receipt.originalTransactionId)")
                            let purchase = PurchaseInfo.init(integrationType: .Amplitude, userId: "", transactionId: receipt.originalTransactionId, amount: 20.0, currency: "usd")
                            OnboardingService.shared.eventRegistered(event: .productPurchased, params: [.screenID: self?.screen.id ?? "none", .screenName: self?.screen.name ?? "none", .productId: product.id, .transactionId : receipt.originalTransactionId, .paymentsInfo: receipt])
                            
                            OnboardingService.shared.sendPurchase(projectId: projectId, transactionId: receipt.originalTransactionId, purchaseInfo: purchase)
                            
                            OnboardingService.shared.sendIntegrationsDetails(projectId: projectId) {error in
                            }
                            
                            self?.closeScreenAfterPurchase(receipt: receipt)
//                            setViewBusy(false)
//                            self?.finishWith(action: self?.screenData.footer.purchase?.action)
                        }
                    } else {
                        closeScreenAfterPurchase(receipt: nil)
//                        setViewBusy(false)
//                        finishWith(action: screenData.footer.purchase?.action)
                    }
                }
            } catch {
                // An error occurred while retrieving the receipt
//                print("Error retrieving the receipt: \(error)")
            }
        }
    }
    
    func closeScreenAfterPurchase(receipt: OnboardingPaymentReceipt?) {
        if let purchase = purchaseHandler {
            _ = purchase(self, receipt)
        }
        
        setViewBusy(false)
        finishWith(action: screenData.footer.purchase?.action)
    }
    
    func finishWith(action: Action?) {
        DispatchQueue.main.async {[weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.onboardingScreen(strongSelf, didFinishWithScreenData: action)
        }
    }
    
    @objc func closeButtonPressed() {
//        guard !isBusy else { return }

        if let closeHandler = closePaywallHandler {
            _ = closeHandler(self)
        }
        
        OnboardingService.shared.eventRegistered(event: .paywallCloseButtonPressed, params: [.screenID: screen.id, .screenName: screen.name])

        finishWith(action: screenData.navigationBar.close?.action)
    }
    
    @objc func restoreButtonPressed() {
        restoreProducts()
    }
    
    func close() {
        if let closeHandler = closePaywallHandler {
            _ = closeHandler(self)
        }
        
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
    
    
    func setup() {
        self.hidesBottomBarWhenPushed = true
        collectionView.isScrollEnabled = OnboardingService.shared.paywallScreenScrollEnabled
        
        setupBackground()
    }
    var useLocalAssetsIfAvailable: Bool { screenData?.useLocalAssetsIfAvailable ?? true }
    
    func setupBackground() {
        backgroundView = backgroundContainerView

        if let background = self.screenData?.styles.background {
            switch background.styles {
            case .typeBackgroundStyleColor(let value):
                backgroundContainerView.backgroundColor = value.color.hexStringToColor
            case .typeBackgroundStyleImage(let value):
                updateBackground(image: value.image, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
            case .typeBackgroundStyleVideo:
                setupBackgroundFor(screenId: screen.id,
                                   using: videoPreparationService)
            }
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
        restoreProducts()
    }
}

// MARK: - Setup methods
private extension PaywallVC {
    
    func setup(footer: PaywallFooter) {
        bottomView.setup(footer: footer)
        bottomView.delegate = self
    }

    func setup(navigationBar: PaywallNavigationBar) {
        if let alignment = navigationBar.styles.closeHorizontalAlignment, screenData.navigationBar.close != nil {
            switch alignment {
            case ._left:
                addCloseButton(isRightSide: false)
                addRestoreButton(isRightSide: false)
            case ._right:
                addCloseButton(isRightSide: true)
                addRestoreButton(isRightSide: true)
            }
        } else {
            addRestoreButton(isRightSide: false)
            closeButton.isHidden = true
        }
    }
    
    func isRestoreInHeader() -> Bool {
        return screenData.navigationBar.restore != nil
    }
    
    func addCloseButton(isRightSide: Bool) {
        guard screenData.navigationBar.close != nil else {
            closeButton.isHidden = true
            return
        }
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.tintColor = screenData.navigationBar.close?.textColor()
        closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)

        NSLayoutConstraint.activate([
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 0),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        if isRightSide {
            NSLayoutConstraint.activate([closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16)])
        } else {
            NSLayoutConstraint.activate([closeButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16)])
        }
        if let appearance = screenData.navigationBar.styles.closeAppearance,
           let time = screenData.navigationBar.styles.closeVisibleAfterTimerValue {
            switch  appearance {
            case .visibleaftertimer:
                    closeButton.isHidden = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + time) {[weak self]  in
                        self?.closeButton.isHidden = false
                    }
            default:
                break
            }
        }
    }
    
    
    func addRestoreButton(isRightSide: Bool) {
        if isRestoreInHeader() {
            restoreButton = UIButton()
            headerView.addSubview(restoreButton)
            restoreButton.translatesAutoresizingMaskIntoConstraints = false
            restoreButton.addTarget(self, action: #selector(restoreButtonPressed), for: .touchUpInside)
            restoreButton.apply(textLabel: screenData.navigationBar.restore)

            NSLayoutConstraint.activate([
                restoreButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 0),
                restoreButton.heightAnchor.constraint(equalToConstant: 40),
                restoreButton.widthAnchor.constraint(equalToConstant: 120)
            ])
            
            if isRightSide {
                restoreButton.contentHorizontalAlignment = .left

                NSLayoutConstraint.activate([restoreButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16)])
            } else {
                restoreButton.contentHorizontalAlignment = .right

                NSLayoutConstraint.activate([restoreButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16)])
            }
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
        case header
        case separator
        case oneTimePurchase
        case listSubscription
        case tileSubscription
        case loading
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
            return [.header]
        case .separator:
            return [.separator]
        case .items:
//            if isLoadingProducts {
//                return [.loading]
//            }
            
            if products.isEmpty {
                let serverProducts = screenData.subscriptions.items
                return serverProducts.compactMap { product in
                    return .listSubscription
                }
            }  else {
                switch style {
                case .subscriptionsList:
                    return products.compactMap { product in
                        if itemFor(product: product) != nil {
                            switch product.type {
                            case .oneTimePurchase:
                                return .listSubscription
                            case .subscription(_):
                                return .listSubscription
                            }
                        } else {
                            return nil
                        }
                    }
                case .subscriptionsTiles:
                    return products.compactMap { product in
                        switch product.type {
                        case .oneTimePurchase:
                            return .tileSubscription
                        case .subscription(_):
                            return .tileSubscription
                        }
                    }
                }
            }
        }
            
    }
    
    
}

struct PaywallCollectionConstants {

//    list.box.styles.paddingLeft ?? 0
//    screenData.subscriptions
    var leadingConstraint: CGFloat = 16
    var trailingConstraint: CGFloat = 16
    
    let centerGapConstraint: CGFloat = 16
        
    let magicGapForCellWidthCalculation: CGFloat = 3


}

extension PaywallVC {
    
    func calculateItemCellSize() -> CGSize {
        let width = collectionView.bounds.width
        let spaces = constants.trailingConstraint + constants.trailingConstraint +  (constants.centerGapConstraint)
        let cellWidth = ((width - spaces)  / 2) - constants.magicGapForCellWidthCalculation

        return .init(width: cellWidth, height: cellWidth)
    }
    
    struct Constants {
        static let defaultHeaderHeight: CGFloat = { UIScreen.isIphoneSE1 ? 180 : 280 }()
        static let sectionsSpacing: CGFloat = { UIScreen.isIphoneSE1 ? 0 : 0 }()
        static let listItemsSpacing: CGFloat = { 4 }()

        static let subscriptionListItemHeight: CGFloat = { UIScreen.isIphoneSE1 ? 60 : 120 }()

        static let subscriptionTileItemSize: CGSize = {
            UIScreen.isIphoneSE1 ? CGSize(width: 120, height: 120) : CGSize(width: 140, height: 150)
        }()
    }
    
}
