//
//  PaywallVC.swift
//  
//
//  Created by Oleg Kuplin on 26.12.2023.
//

import UIKit
import ScreensGraph

final class PaywallVC: BaseChildScreenGraphViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomView: PaywallBottomView!
    
    var selectedItem = [Int]()

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

}

// MARK: - PaywallBottomViewDelegate
extension PaywallVC: PaywallBottomViewDelegate {
    
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
        case .listSubscription(let configuration):
            let index = indexPath.row
            let isSelected =  selectedItem.contains(index)
            
            let cell = collectionView.dequeueCellOfType(PaywallListSubscriptionCell.self, at: indexPath)
            
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
        case .header(_), .separator:
            return
        case .listSubscription(let item):
            let index = indexPath.row
            
            if selectedItem.contains(index) {
                selectedItem.removeObject(object: index)
            } else {
                selectedItem.append(index)
            }
            
            if #available(iOS 15.0, *) {
                collectionView.reconfigureItems(at: [indexPath])
            } else {
                collectionView.reloadItems(at: [indexPath])
            }
//            self.delegate?.onboardingChildScreenUpdate(value: selectedItem, description: item.title.textByLocale(), logAnalytics: true)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let headerCell = collectionView.visibleCells.first(where: { $0 is PaywallHeaderCell }) as? PaywallHeaderCell {
            headerCell.setScrollOffset(scrollView.contentOffset)
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
        default:
            height = row.height
        }
        return .init(width: view.bounds.width, height: height)
    }
    
    func calculateHeaderSize(in sections: [SectionType]) -> CGFloat {
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
    func setup() {
        setupCollectionView()
        bottomView.delegate = self
    }
    
    func setupCollectionView() {
        collectionView.registerCellNibOfType(PaywallHeaderCell.self)
        collectionView.registerCellNibOfType(PaywallListSubscriptionCell.self)
        collectionView.registerCellNibOfType(PaywallSeparatorCell.self)
        
        collectionView.contentInsetAdjustmentBehavior = .never
        
        collectionView.delegate = self
        collectionView.dataSource = self
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
        
        var height: CGFloat {
            switch self {
            case .header:
                return 0
            case .separator:
                return 1
            case .listSubscription:
                return 77
            }
        }
    }
    
    struct HeaderCellConfiguration {
        let imageURL: URL
        let title: String
        let subtitle: String
    }
    
    struct ListSubscriptionCellConfiguration {
        
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
            return [.listSubscription(.init()),
                    .listSubscription(.init()),
                    .listSubscription(.init())]
        }
    }
}

extension PaywallVC {
    struct Constants {
        static let sectionsSpacing: CGFloat = 24
        static let listItemsSpacing: CGFloat = 16
    }
}

@available(iOS 17, *)
#Preview {
    PaywallVC.nibInstance()
}

extension PaywallVC.HeaderCellConfiguration {
    static func mock() -> PaywallVC.HeaderCellConfiguration {
        .init(imageURL: URL(string: "https://img.freepik.com/free-photo/painting-mountain-lake-with-mountain-background_188544-9126.jpg?size=626&ext=jpg&ga=GA1.1.1546980028.1703462400&semt=sph")!,
              title: "Do you have a question? ",
              subtitle: "Just ask it to our lawyer and get a quick and high-quality answer. ")
    }
}
