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
    
    @Submodel
    var todo: Todo
    
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
    
    init(todo: Todo, transaction: Crush.Transaction, isPresenting: Binding<Bool>) {
        self.transaction = transaction
        self.todo = todo
        self.isDueDateEnabled = todo.dueDate != nil
        self.dueDate = todo.dueDate ?? Date()
        self.dateString = "Not set"
        self._isPresenting = isPresenting
        
        super.init()
        
        bindSubmodel()
        setupBindings()
    }

    func setupBindings() {
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
            .removeDuplicates()
            .assign(to: \.dueDate, on: todo)
            .store(in: &cancellables)

        $dueDate
            .dropFirst()
            .map{ Swift.Optional.some($0) }
            .removeDuplicates()
            .assign(to: \.dueDate, on: todo)
            .store(in: &cancellables)
    }
    
    func save() {
        transaction.commit()
    }
}

extension Publisher where Self.Failure == Never {
    public func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, on object: Root) -> AnyCancellable {
        self.sink { [weak root = object] in
            root?[keyPath: keyPath] = $0
        }
    }
}
