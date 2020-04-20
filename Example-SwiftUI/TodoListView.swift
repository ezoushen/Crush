//
//  TodoListView.swift
//  Example-SwiftUI
//
//  Created by 沈昱佐 on 2020/4/18.
//

import SwiftUI
import Crush

struct TodoListView: View {
    
    @EnvironmentObject
    var viewModel: TodoListViewModel
    
    @State
    var isPresenting: Bool = false
    
    var body: some View {
        
        NavigationView {
            List(viewModel.todos, id: \.self){ todo in
                HStack {
                    VStack(alignment: .leading, spacing: 1.0) {
                        Text(todo.content).font(.system(size: 17.0))
                        if todo.memo != nil {
                            Text(todo.memo ?? "").font(.system(size: 12.0))
                        }
                    }
                    Spacer()
                    VStack {
                        Color(todo.isFinished ? .green : .red)
                            .frame(width: 10.0, height: 10.0)
                            .mask(Circle().frame(width: 10.0, height: 10.0))
                    }
                }
                    .padding(.horizontal, 10.0)
                    .frame(height: 35.0)
                    .onTapGesture {
                        self.viewModel.detailViewModel = self.viewModel.createDetailViewModel(todo: todo)
                        self.viewModel.isPresenting = true
                    }
            }
            .navigationBarTitle("Todo List", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Edit") { },
                trailing: Button("Add") {
                    self.viewModel.detailViewModel = self.viewModel.addTodoDetailViewModel()
                    self.viewModel.isPresenting = true
                }
            )
        }
            .onAppear {
                self.viewModel.loadAllTodos()
            }
    
            .sheet(isPresented: self.viewModel.binding(\.isPresenting)) {
                TodoDetailView()
                    .environmentObject(self.viewModel.detailViewModel!)
            }
    }
}

#if DEBUG
struct TodoListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TodoListViewModel()
        return TodoListView().environmentObject(viewModel)
    }
}
#endif
