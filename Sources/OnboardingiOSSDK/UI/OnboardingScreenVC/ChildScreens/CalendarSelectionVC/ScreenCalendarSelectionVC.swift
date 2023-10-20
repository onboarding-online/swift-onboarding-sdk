//
//  StoryboardExampleViewController.swift
//
//
//  Copyright 2023 Onboarding.online on 09.03.2023.
//

import UIKit
import EventKit

import ScreensGraph

class ScreenCalendarSelectionVC: BaseChildScreenGraphViewController  {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    @IBOutlet weak var d1: UILabel!
    @IBOutlet weak var d2: UILabel!
    @IBOutlet weak var d3: UILabel!
    @IBOutlet weak var d4: UILabel!
    @IBOutlet weak var d5: UILabel!
    @IBOutlet weak var d6: UILabel!
    @IBOutlet weak var d7: UILabel!
    
    @IBOutlet weak var dayOfWeekView: UIStackView!


    var screenData: ScreenTitleSubtitleCalendar!
    var selectedItem = [Int]()
        
    @IBOutlet weak var calendarView: KOCalendarView!
    
    static func instantiate(screenData: ScreenTitleSubtitleCalendar) -> ScreenCalendarSelectionVC {
        let titleSubtitleCalendarVC = ScreenCalendarSelectionVC.storyBoardInstance()
        titleSubtitleCalendarVC.screenData = screenData
        return titleSubtitleCalendarVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLabels()
        setupCalendarView()
    }
}

extension ScreenCalendarSelectionVC: KOCalendarViewDataSource {
    
    var configurator: KOCalendarViewConfigurator<KOCalendarViewCell>? {
        let calendar = Calendar.current
        
        let currentDate = Date()
        
        if let startDate = calendar.date(byAdding: .month, value: -1, to: currentDate),
           let endDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            let config = KOCalendarViewConfigurator(cellType: KOCalendarViewCell.self, isCellFromNib: true, startDate: startDate, endDate: endDate, firstWeekday: .mon)
            return config

        }
        
        return nil
    }
}



private extension ScreenCalendarSelectionVC {
    
    func setupCalendarView() {
        calendarView.calendarDelegate = self
        calendarView.calendarDataSource = self
        calendarView.screenData = self.screenData
        
        if let color = screenData.calendar.styles.headerBackgroundColor?.hexStringToColor {
            dayOfWeekView.backgroundColor = color
        }
        
        if let color = screenData.calendar.styles.backgroundColor?.hexStringToColor {
            calendarView.backgroundColor = color
        }

        d1.text = EKWeekday.monday.visibleShortName
        d2.text = EKWeekday.tuesday.visibleShortName
        d3.text = EKWeekday.wednesday.visibleShortName
        d4.text = EKWeekday.thursday.visibleShortName
        d5.text = EKWeekday.friday.visibleShortName
        d6.text = EKWeekday.saturday.visibleShortName
        d7.text = EKWeekday.sunday.visibleShortName
        
        self.view.sendSubviewToBack(calendarView)
    }
    
    func setupLabels() {
        titleLabel.apply(text: screenData.title)
        subtitleLabel.apply(text: screenData.subtitle)
    }
    
}


extension ScreenCalendarSelectionVC: KOCalendarViewDelegate {
    
    func koCalendarView(_ koCalendarView: KOCalendarView, willConfigureCell cell: KOCalendarViewCell) {
        
    }
    
    func koCalendarView(_ selectedDays:[Date]) {
        self.delegate?.onboardingChildScreenUpdate(value: selectedDays, description: nil, logAnalytics: true)
    }
    
}
