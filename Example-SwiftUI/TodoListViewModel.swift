//
//  TodoListViewModel.swift
//  Example-SwiftUI
//
//  Created by 沈昱佐 on 2020/4/18.
//

import SwiftUI
import Crush
import Combine

final class TodoListViewModel: ViewModel, ObservableObject {
    
    @Environment(\.dataContainer)
    var dataContainer: DataContainer
    
    @Published
    var todos: [Todo.ReadOnly] = []
    
    @Published
    var isPresenting: Bool = false
    
    @Published
    var detailViewModel: TodoDetailViewModel? = nil
        
    override init() {
        super.init()
        setupBindings()
    }
    
    func setupBindings() {
        $isPresenting
            .filter{ !$0 }
            .sink { [unowned self] _ in
                self.detailViewModel = nil
            }
            .store(in: &cancellables)
    }
}

extension TodoListViewModel {
    func loadAllTodos() {
        todos = try! dataContainer.fetch(for: Todo.self).exec()
    }
    
    func addTodoDetailViewModel() -> TodoDetailViewModel {
        let transaction = dataContainer.startTransaction()
        let todo: Todo.ReadOnly = try! transaction.sync { context in
            let todo = context.create(entiy: Todo.self)
            return todo
        }
        let viewModel = TodoDetailViewModel(todo: todo, transaction: transaction, isPresenting: binding(\.isPresenting))
        
        viewModel
            .didDismiss
            .sink {
                self.loadAllTodos()
            }
            .store(in: &viewModel.cancellables)
        
        return viewModel
    }
    
    func createDetailViewModel(todo: Todo.ReadOnly) -> TodoDetailViewModel {
        let transaction = dataContainer.startTransaction()
        let todo = transaction.receive(todo)
        print(todo)
        return TodoDetailViewModel(todo: todo, transaction: transaction, isPresenting: binding(\.isPresenting))
    }
}
