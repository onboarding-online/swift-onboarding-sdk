//
//  PaywallVC.swift
//  
//
//  Created by Oleg Kuplin on 26.12.2023.
//

import UIKit
import ScreensGraph

final class PaywallVC: BaseChildScreenGraphViewController {
    
    static func instantiate(paymentService: OnboardingPaymentServiceProtocol) -> PaywallVC {
        let paywallVC = PaywallVC.nibInstance()
        paywallVC.paymentService = paymentService
        return paywallVC
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomView: PaywallBottomView!
    @IBOutlet weak var gradientView: GradientView!
    
    private var paymentService: OnboardingPaymentServiceProtocol!
    private var selectedItem: Int = 0
    private var isLoading = true

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

}

// MARK: - PaywallBottomViewDelegate
extension PaywallVC: PaywallBottomViewDelegate {
    func paywallBottomViewBuyButtonPressed(_ paywallBottomView: PaywallBottomView) {
        
    }
    
    func paywallBottomViewPPButtonPressed(_ paywallBottomView: PaywallBottomView) {
        
    }
    
    func paywallBottomViewTACButtonPressed(_ paywallBottomView: PaywallBottomView) {
        
    }
    
    func paywallBottomViewRestoreButtonPressed(_ paywallBottomView: PaywallBottomView) {
        Task {
            do {
                try await paymentService?.restorePurchases()
            } catch {
                handleError(error, message: "Failed to restore purchases")
            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension PaywallVC: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        allSections().count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section = allSections()[section]
        
        return rowsFor(section: section).count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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
            let isSelected = selectedItem == index
            
            let cell = collectionView.dequeueCellOfType(PaywallListSubscriptionCell.self, at: indexPath)
            cell.setWith(configuration: configuration, isSelected: isSelected)
            
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate
extension PaywallVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = allSections()[indexPath.section]
        let row = rowsFor(section: section)[indexPath.row]
        
        switch row {
        case .header(_), .separator, .loading:
            return
        case .listSubscription(let item):
            let index = indexPath.row
            if selectedItem != index {
                var indexPathsToReload = [indexPath]
                indexPathsToReload.append(IndexPath(row: selectedItem, section: indexPath.section))
                selectedItem = index
                reloadCellsAt(indexPaths: indexPathsToReload)
            }
            
//            self.delegate?.onboardingChildScreenUpdate(value: selectedItem, description: item.title.textByLocale(), logAnalytics: true)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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

extension PaywallVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
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
        if isLoading {
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let section = allSections()[section]
        
        switch section {
        case .header, .separator:
            return 0
        case .items:
            return Constants.listItemsSpacing
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let section = allSections()[section]
        switch section {
        case .header, .separator:
            return .init(top: 0, left: 0,
                         bottom: Constants.sectionsSpacing, right: 0)
        case .items:
            return .zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }
}

// MARK: - Private methods
private extension PaywallVC {
    func loadProducts() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.didLoadProducts()
        }
    }
    
    func didLoadProducts() {
        self.isLoading = false
        let sections = allSections()
        self.collectionView.performBatchUpdates {
            collectionView.reloadSections(IndexSet(0..<sections.count))
        }
    }
    
    @objc func closeButtonPressed() {
        
    }
    
    @MainActor
    func handleError(_ error: Error,
                     message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
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
//        navigationController?.navigationBar.isTranslucent = true
        
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
        case listSubscription(ListSubscriptionCellConfiguration)
        case loading
        
        var height: CGFloat {
            switch self {
            case .header, .loading:
                return 0
            case .separator:
                return 1
            case .listSubscription:
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
            if isLoading {
                return [.loading]
            }
            return [.listSubscription(.init(badgePosition: .left)),
                    .listSubscription(.init(badgePosition: .center)),
                    .listSubscription(.init(badgePosition: .right)),
                    .listSubscription(.init(badgePosition: .none))]
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

private extension PaywallVC.HeaderCellConfiguration {
    static func mock() -> PaywallVC.HeaderCellConfiguration {
        .init(imageURL: URL(string: "https://img.freepik.com/free-photo/painting-mountain-lake-with-mountain-background_188544-9126.jpg?size=626&ext=jpg&ga=GA1.1.1546980028.1703462400&semt=sph")!,
              title: "Do you have a question? ",
              subtitle: "Just ask it to our lawyer and get a quick and high-quality answer. ")
    }
}

@available(iOS 17, *)
#Preview {
    let vc = PaywallVC.nibInstance()
    let nav = UINavigationController(rootViewController: vc)
    
    return nav
}

//import SwiftUI
//struct PaywallVCPreviews: PreviewProvider {
//    static var previews: some View {
//        UIViewControllerPreview {
//            PaywallVC.nibInstance()
//        }
//        .edgesIgnoringSafeArea(.all)
//        .preferredColorScheme(.dark)
//    }
//}
