//
//  TodoDetailViewModel.swift
//  Example-SwiftUI
//
//  Created by 沈昱佐 on 2020/4/18.
//

import Combine
import Crush
import SwiftUI

final class TodoDetailViewModel: ViewModel, ObservableObject {
    let transaction: Crush.Transaction
    
    var todo: Todo.ReadOnly
    
    @Published
    private(set) var dateString: String
    
    @Published
    var isDueDateEnabled: Bool
    
    @Published
    var dueDate: Date
    
    @Binding
    var isPresenting: Bool
            
    static var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter
    }()
    
    init(todo: Todo.ReadOnly, transaction: Crush.Transaction, isPresenting: Binding<Bool>) {
        self._isPresenting = isPresenting
        self.transaction = transaction
        self.todo = todo
        self.isDueDateEnabled = todo.dueDate != nil
        self.dueDate = todo.dueDate ?? Date()
        self.dateString = {
            guard let dueDate = todo.dueDate else { return "Not set" }
            return Self.dateFormatter.string(from: dueDate)
        }()
        
        super.init()
        
        setupBindings()
    }

    func setupBindings() {
        todo.objectWillChange
            .print("\(Date())")

            .sink {[unowned self] in
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        todo.observe(\.$dueDate)
            .removeDuplicates()
            .map {
                guard let date = $0 else { return "Not set" }
                return Self.dateFormatter.string(from: date)
            }
            .assign(to: \.dateString, on: self)
            .store(in: &cancellables)

        todo.observe(\.$dueDate)
            .compactMap{ $0 }
            .removeDuplicates()
            .assign(to: \.dueDate, on: self)
            .store(in: &cancellables)

        $isDueDateEnabled
            .map { [unowned self] in
                $0 ? (self.todo.dueDate ?? self.dueDate) : nil
            }
    .print("isDueDateEnabled")
            .removeDuplicates()
            .assign(to: \.dueDate, on: todo.edit(in: transaction))
            .store(in: &cancellables)
        
        $dueDate
            .dropFirst()
            .map{ Swift.Optional.some($0) }
            .print("dueDate")
            .removeDuplicates()
            .assign(to: \.dueDate, on: todo.edit(in: transaction))
            .store(in: &cancellables)
    }
    
    func save() {
        try? transaction.commit()
    }
}
