//
//  KOCalendarViewCell.swift
//  KOCalendar
//
//  Created by Oleg Home on 14/10/2018.
//  Copyright © 2018 Oleg Home. All rights reserved.
//

import UIKit
import ScreensGraph

class KOCalendarViewCell: UICollectionViewCell {

    
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var IsTodayLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var checkbox: UIImageView!
    
    var screenData: ScreenTitleSubtitleCalendar!


    fileprivate(set) var koDay: KODay?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        selectedView.layer.cornerRadius = selectedView.bounds.width / 2
    }
    
    func setupWith(koDay: KODay, isSelected: Bool) {
        self.koDay = koDay
        let currentDay: CalendarDay
        
        if koDay.isToday {
            currentDay = screenData.calendar.days.today
            IsTodayLabel.isHidden = false
            checkbox.isHidden = false

        } else if koDay.date > Date()  {
            currentDay = screenData.calendar.days.future
            
            checkbox.isHidden = true
            IsTodayLabel.isHidden = true
        } else {
            IsTodayLabel.isHidden = true
            checkbox.isHidden = false
            currentDay = screenData.calendar.days.past
        }
        dateLabel.apply(text: currentDay.labelBlock)
        checkbox.apply(checkbox: currentDay.checkBox, isSelected: isSelected)
        
        
        if koDay.isInCurrentMonth {
            dateLabel.text = "\(koDay.dayNumber)"
        } else {
            dateLabel.text = ""
            checkbox.isHidden = true
            IsTodayLabel.isHidden = true
        }
    }

}
