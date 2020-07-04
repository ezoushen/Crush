//
//  TodoListViewController.swift
//  Crush
//
//  Created by mill010363 on 01/20/2020.
//  Copyright (c) 2020 mill010363. All rights reserved.
//

import UIKit
import Crush

class TodoListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var createButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    lazy var container: DataContainer! = {
        let connection = Connection(type: .sql,
                                    name: "Crush-Example",
                                    version: CurrentSchema())
        return try! DataContainer(connection: connection)
    }()

    var todos: [Todo.ReadOnly] = [] {
        didSet {
            todos.sort(by: { $1.isFinished && !$0.isFinished })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            // Load all tasks
            self.todos = try! self.container.fetch(for: Todo.self).exec()
            // Reload table view
            self.tableView.reloadData()
        }
    }
    
    @IBAction func didPressCreateButton() {
        let todo: Todo.ReadOnly = try! container.startTransaction().sync { context -> Todo in
            let todo = context.create(entiy: Todo.self)
            return todo
        }
        performSegue(withIdentifier: "TASK_DETAIL_VIEW",
                     sender: [
                        "value": todo,
                        "mode": TodoEditMode.create
                    ])
    }
    
    @IBAction func didPressEditButton() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        editButton.title = tableView.isEditing ? "Finish" : "Edit"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "TASK_DETAIL_VIEW":
            guard let destination = segue.destination as? TodoViewController,
                let info = sender as? [String: Any],
                let todo = info["value"] as? Todo.ReadOnly,
                let mode = info["mode"] as? TodoEditMode else { return }
            destination.mode = mode
            destination.todo = todo
            destination.delegate = self
            destination.transaction = container.startTransaction()
        default: break
        }
    }
}

extension TodoListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let todo = todos[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
            let todo = self.todos.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            self.container.startTransaction().edit(todo).async { context, todo in
                context.delete(todo)
                try! context.commit()
            }
            completion(true)
        }
        
        let doneAction = UIContextualAction(style: .normal, title: "Done") { (action, view, completion) in
            try! self.container.startTransaction().edit(todo).sync { context, todo in
                todo.isFinished = true
                try context.commit()
            }
            let todo = self.todos.remove(at: indexPath.row)
            self.todos.append(todo)
            tableView.moveRow(at: indexPath, to: IndexPath(row: self.todos.count - 1, section: 0))
            tableView.reloadRows(at: [IndexPath(row: self.todos.count - 1, section: 0)], with: .automatic)
            completion(true)
        }
        
        let undoneAction = UIContextualAction(style: .normal, title: "Undone") { (action, view, completion) in
            try! self.container.startTransaction().edit(todo).sync { context, todo in
                todo.isFinished = false
                try context.commit()
            }
            let todo = self.todos.remove(at: indexPath.row)
            self.todos.insert(todo, at: 0)
            tableView.moveRow(at: indexPath, to: IndexPath(row: 0, section: 0))
            tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            completion(true)
        }
        
        return .init(actions: todo.isFinished ? [deleteAction, undoneAction] : [deleteAction, doneAction])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        todos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let _cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard let cell = _cell as? TodoTableViewCell else { return _cell }
        let todo = todos[indexPath.row]
        cell.setup(by: todo)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let todo = todos[indexPath.row]
        performSegue(withIdentifier: "TASK_DETAIL_VIEW",
                     sender: [
                        "value": todo,
                        "mode": TodoEditMode.modify
                    ])
    }
}

extension TodoListViewController: TodoViewDelegate {
    func didCancelModification(type: TodoEditMode, todo: Todo.ReadOnly) {
        switch type {
        case .create:
            try! container.startTransaction().edit(todo).sync { context, todo in
                context.delete(todo)
                try context.commit()
            }
        case .modify:
            tableView.reloadData()
        }
    }
    
    func didSaveModification(type: TodoEditMode, todo: Todo.ReadOnly) {
        defer {
            tableView.reloadData()
        }
        
        switch type {
        case .create:
            todos.append(todo)
        default: break
        }
    }
}
