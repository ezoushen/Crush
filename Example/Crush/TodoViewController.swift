//
//  TodoViewController.swift
//  Crush_Example
//
//  Created by 沈昱佐 on 2020/1/21.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import Crush

protocol TodoViewDelegate: class {
    func didCancelModification(type: TodoEditMode, todo: Todo)
    func didSaveModification(type: TodoEditMode, todo: Todo)
}

enum TodoEditMode {
    case create, modify
    
    var title: String {
        switch self {
        case .create: return "Delete"
        case .modify: return "Cancel"
        }
    }
}

class TodoViewController: UIViewController {
    private static let _dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var memoTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    var transaction: Transaction?
    weak var delegate: TodoViewDelegate?
    
    var todo: Todo!
    var mode: TodoEditMode = .modify
    
    private var _observers: [Any] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI(by: todo)
        observeValueChanged()
    }
    
    func setupUI(by todo: Todo?) {
        guard let todo = todo else { return }
        titleTextField.text = todo.content
        memoTextView.text = todo.memo ?? ""
        datePicker.date = todo.dueDate
        dueDateLabel.text = Self._dateFormatter.string(from: todo.dueDate)
        cancelButton.setTitle(mode.title, for: .normal)
    }
    
    func observeValueChanged() {
        let gesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(gesture)
        datePicker.addTarget(self, action: #selector(dueDateValueChanged(_:)), for: .valueChanged)
        titleTextField.addTarget(self, action: #selector(titleChanged(_:)), for: .editingChanged)
        memoTextView.delegate = self
    }
    
    @objc func dueDateValueChanged(_ sender: UIDatePicker?) {
        let date = sender?.date ?? todo.dueDate
        dueDateLabel.text = Self._dateFormatter.string(from: date)
        transaction?.edit(todo).async { context, todo in
            todo.dueDate = date
        }
    }
    
    @objc func titleChanged(_ sender: UITextField?) {
        let title = sender?.text ?? todo.content
        transaction?.edit(todo).async { context, todo in
            todo.content = title
        }
    }
    
    @IBAction func didPressSaveButton() {
        transaction?.commit()
        delegate?.didSaveModification(type: mode, todo: todo)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didPressCancelButton() {
        delegate?.didCancelModification(type: mode, todo: todo)
        dismiss(animated: true, completion: nil)
    }
}

extension TodoViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let memo = textView.text ?? ""
        transaction?.edit(todo).async { context, todo in
            todo.memo = memo
        }
    }
}
