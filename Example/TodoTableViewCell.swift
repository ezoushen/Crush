//
//  TodoTableViewCell.swift
//  Crush_Example
//
//  Created by 沈昱佐 on 2020/1/21.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

class TodoTableViewCell: UITableViewCell {
    private static var _dateFormatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var statusIndicatorView: UIView!
    
    override func awakeFromNib() {
        statusIndicatorView.layer.cornerRadius = statusIndicatorView.frame.height / 2.0
    }
    
    func setup(by todo: Todo) {
        titleLabel.text = todo.content
        dateLabel.text = Self._dateFormatter.string(from: todo.dueDate)
        statusIndicatorView.backgroundColor = todo.isFinished ? .green : .red
    }
}
