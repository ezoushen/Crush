//
//  TodoDetailViewModel.swift
//  Example-SwiftUI
//
//  Created by 沈昱佐 on 2020/4/18.
//

import Combine
import Crush
import SwiftUI

final class TodoDetailViewModel: ObservableObject, ViewModel {
    let transaction: Crush.Transaction
    
    @Published
    var todo: Todo
    
    @Published
    var isDueDateEnabled: Bool
    
    @Published
    var dateString: String
    
    @Binding
    var isPresenting: Bool
    
    var cancellables: Set<AnyCancellable> = []
    
    static var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter
    }()
    
    init(todo: Todo, transaction: Crush.Transaction, isPresenting: Binding<Bool>) {
        self.transaction = transaction
        self.todo = todo
        self.isDueDateEnabled = todo.dueDate != nil
        self.dateString = Self.dateFormatter.string(from: todo.edit(in: transaction).dueDate ?? Date())
        self._isPresenting = isPresenting
    }
    
    func setupBindings() {
        $isDueDateEnabled.sink { [unowned self] isEnabled in
            try? self.transaction.edit(self.todo).sync { context, todo in
                todo.dueDate = isEnabled ? (todo.dueDate ?? Date()) : nil
            }
        }
            .store(in: &cancellables)
        
        let todo = self.todo.edit(in: transaction)
        
        todo.observe(\Todo.$dueDate) { 
            print($0)
        }
//            .map {
//                Self.dateFormatter.string(from: todo.dueDate ?? Date())
//            }
//            .removeDuplicates()
//            .assign(to: \.dateString, on: self)
//            .store(in: &cancellables)
    }
    
    func fullDateString() -> String {
        ""
    }
}
