//
//  TodoListViewModel.swift
//  Example-SwiftUI
//
//  Created by 沈昱佐 on 2020/4/18.
//

import SwiftUI
import Crush
import Combine

final class TodoListViewModel: ObservableObject, ViewModel {
    
    @Environment(\.dataContainer)
    var dataContainer: DataContainer
    
    @Published
    var todos: [Todo] = []
    
    @Published
    var isPresenting: Bool = false
    
    @Published
    var detailViewModel: TodoDetailViewModel? = nil
}

extension TodoListViewModel {
    func loadAllTodos() {
        todos = try! dataContainer.fetch(for: Todo.self).exec()
    }
    
    func addTodoDetailViewModel() -> TodoDetailViewModel {
        let transaction = dataContainer.startTransaction()
        let todo: Todo = try! transaction.sync { context in
            defer {
                context.stash()
            }
            let todo = context.create(entiy: Todo.self)
            return todo
        }
        return TodoDetailViewModel(todo: todo, transaction: transaction, isPresenting: binding(\.isPresenting))
    }
    
    func createDetaulViewModel(todo: Todo) -> TodoDetailViewModel {
        let transaction = dataContainer.startTransaction()
        return TodoDetailViewModel(todo: todo, transaction: transaction, isPresenting: binding(\.isPresenting))
    }
}
