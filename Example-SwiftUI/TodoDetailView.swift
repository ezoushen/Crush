//
//  TodoDetailView.swift
//  Example-SwiftUI
//
//  Created by 沈昱佐 on 2020/4/18.
//

import SwiftUI
import Crush

struct TodoDetailView: View {
    @State
    var text: String = ""
    
    @State
    var memo: String = ""
    
    @State
    var date: Date = Date()
    
    @EnvironmentObject
    var viewModel: TodoDetailViewModel
    
    var body: some View {
        VStack {
            HStack {
                Button("Cancel") {
                    self.viewModel.isPresenting = false
                }
                Spacer()
                Button("Save") {
                    self.viewModel.save()
                    self.viewModel.isPresenting = false
                }
            }
                .font(.system(size: 18.0))
            TextField(
                "Title",
                text: viewModel.todo.edit(in: viewModel.transaction).bindings().content ?? ""
            )
                .font(.system(size: 42.0))
            Divider()
            HStack {
                Text("Memo:").font(.system(size: 14.0))
                Spacer()
            }
            TextView(
                Text("Write down your memo")
                    .font(.system(size: 14.0))
                    .foregroundColor(.gray),
                text: viewModel.todo.edit(in: viewModel.transaction).bindings().memo ?? ""
            )
            HStack {
                Text("Due Date: \(viewModel.dateString)")
                    .lineLimit(1)
                Spacer()
                Toggle("", isOn: $viewModel.isDueDateEnabled).fixedSize(horizontal: true, vertical: true)
            }
            DatePicker(
                "",
                selection: $viewModel.dueDate
            )
                .labelsHidden()
                .disabled(!viewModel.isDueDateEnabled)
        }
            .font(.system(size: 14.0))
            .padding(.horizontal, 15)
            .padding(.top, 10.0)
    }
}

#if DEBUG
struct TodoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let container = DataContainerKey.defaultValue
        let transaction = container.startTransaction()
        let todo: Todo.ReadOnly = transaction.sync { backgroundTransactionContext in
            let todo = backgroundTransactionContext.create(entiy: Todo.self)
            todo.content = "CONTENT"
            todo.memo = "MEMO"
            return todo
        }
        return TodoDetailView().environmentObject( TodoDetailViewModel(todo: todo, transaction: transaction, isPresenting: State(initialValue: false).projectedValue))
    }
}
#endif
