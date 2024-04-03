//
//  KOCollectionView.swift
//  KOCalendar
//
//  Created by Oleg Home on 15/09/2018.
//  Copyright © 2018 Oleg Home. All rights reserved.
//

import UIKit
import ScreensGraph

protocol KOCalendarViewDataSource: AnyObject {
    var configurator: KOCalendarViewConfigurator<KOCalendarViewCell>? { get }
}

protocol KOCalendarViewDelegate: AnyObject {
    func koCalendarView(_ koCalendarView: KOCalendarView, willConfigureCell cell: KOCalendarViewCell)
    func koCalendarView(_ selectedDays:[Date])

}
 
struct KOCalendarViewConfigurator<T: KOCalendarViewCell> {
    let cellType: T.Type
    let isCellFromNib: Bool
    let startDate: Date
    let endDate: Date
    let firstWeekday: WeekDay
}

class KOCalendarView: UICollectionView {

    fileprivate let calendar = Calendar.current
    fileprivate let dayFormatter = DateFormatter()
    fileprivate let KOCalendarViewQueue = DispatchQueue(label: "KOCalendarViewQueue")
    fileprivate let mainQueue = DispatchQueue.main
 
    fileprivate(set) var startDate: Date!
    fileprivate(set) var endDate: Date!
    fileprivate var configuration: KOCalendarViewConfigurator<KOCalendarViewCell>?
    fileprivate var monthSymbols = [String]()
    fileprivate var monthsData = ContiguousArray<KOMonth>()
    
    weak var calendarDataSource: KOCalendarViewDataSource? { didSet { setup() } }
    weak var calendarDelegate: KOCalendarViewDelegate?
    var selectedItem = [Date]()
    
    var screenData: ScreenTitleSubtitleCalendar!

}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension KOCalendarView:  UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return monthsData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return monthsData[section].days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let configuration = self.configuration else {
            return UICollectionViewCell()
        }
        
        let cell = self.dequeueCellOfType(configuration.cellType, at: indexPath)
        cell.screenData = screenData
        let day = monthsData[indexPath.section].days[indexPath.row]
        
        let isSelected = selectedItem.contains(day.date)

        cell.setupWith(koDay: day, isSelected: isSelected)
                
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        var reusableView : UICollectionReusableView? = nil

        // Create header
        if (kind == UICollectionView.elementKindSectionHeader) {
            // Create Header

            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header", for: indexPath ) as! KOCalendarCollectionViewHeader

            let month = monthsData[indexPath.section]

            headerView.monthNameLabel.text = month.monthName
            reusableView = headerView
        }
        return reusableView!
    }
    
    
}

// MARK: - UICollectionViewDelegate
extension KOCalendarView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let day = monthsData[indexPath.section].days[indexPath.row]
            
        if day.isInCurrentMonth {
            if selectedItem.contains(day.date) {
                selectedItem.removeObject(object: day.date)
            } else {
                selectedItem.append(day.date)
            }
        }

        collectionView.reloadItems(at: [indexPath])

        calendarDelegate?.koCalendarView(selectedItem)
//        self.value = selectedItem
    }
}

// MARK: - Setup methods
fileprivate extension KOCalendarView {
    
    func setup() {
        self.configuration = calendarDataSource?.configurator
        setupDateFormatter()
        setupStartEndDate()
        setupCollectionView()
    }
    
    func setupDateFormatter() {
        dayFormatter.dateFormat = "d"
        monthSymbols = dayFormatter.monthSymbols
    }
    
    func setupCollectionView() {
        guard let configurator = self.configuration else { return }
        
        if configurator.isCellFromNib {
        let cellClassName = String(describing: configurator.cellType)
            self.register(UINib(nibName: cellClassName, bundle: .module), forCellWithReuseIdentifier: cellClassName)
        }
        
//        self.register(KOCalendarCollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "dfssdf")

        let nib = UINib(nibName: KOCalendarCollectionViewHeader.className, bundle: .module)
        self.register( nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")


        
        delegate = self
        dataSource = self
        
        let flowLayout = CalendarCollectionViewFlowLayout(spacing: 0, scrollDirection: .vertical)
        flowLayout.headerReferenceSize = CGSize(width: bounds.width, height: 50)
        self.collectionViewLayout = flowLayout
    }
    
    func setupStartEndDate() {
        guard let configurator = self.configuration else { return }

        let calendar = self.calendar
        let firstWeekday = configurator.firstWeekday

        KOCalendarViewQueue.async { [weak self] in
            Thread.current.name = "KOCalendarView Thread"
            
            let startDate = configurator.startDate
            let endDate = configurator.endDate
            
            let monthsInPeriod = calendar.dateComponents([.month], from: startDate, to: endDate).month ?? 0
            var months = ContiguousArray<KOMonth>()
            months.reserveCapacity(monthsInPeriod + 1)

            for i in 0..<monthsInPeriod {
                if let monthDate = calendar.date(byAdding: .month, value: i, to: startDate) {
                    let dateComponents = calendar.dateComponents([.year, .month], from: monthDate)
                    if let year = dateComponents.year,
                        let monthNumber = dateComponents.month {
                    
                        let month = KOMonth(year: year, monthNumber: monthNumber, firstWeekday: firstWeekday, calendar: calendar)
                        
                        months.append(month)
                    }
                }
            }
            
            self?.startDate = startDate
            self?.endDate = endDate
            
            self?.monthsData = months
            self?.mainQueue.async { [weak self] in
                self?.reloadData()
            }
        }
    }
    
}

extension UICollectionView {
    func dequeueCellOfType<T: UICollectionViewCell>(_ type: T.Type, at indexPath: IndexPath) -> T {
        return self.dequeueReusableCell(withReuseIdentifier: String(describing: type), for: indexPath) as! T
    }
}
