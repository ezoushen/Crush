//
//  Schema.swift
//  Crush_Example
//
//  Created by 沈昱佐 on 2020/1/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Crush
import Foundation

class V1: SchemaOrigin {
    override var entities: [Entity.Type] {
        [
            V1.TodoList.self,
            V1.Todo.self
        ]
    }
    
    class TodoList: EntityObject {
        @Value.String
        var name: String! = ""
    }
    
    class Todo: EntityObject {
        @Value.String
        var title: String! = ""
        
        @Value.Date
        var dueDate: Date! = Date()
        
        @Value.Bool
        var isFinished: Bool! = false
        
        @Optional.Value.String
        var memo: String?
    }
}

class V2: Schema<V1> {
    override var entities: [Entity.Type] {
        [
            V1.TodoList.self,
            V2.Todo.self
        ]
    }
    
    class Todo: EntityObject {
        @Value.String
        var content: String! = ""
        
        @Value.Date
        var dueDate: Date! = Date()
        
        @Value.Bool
        var isFinished: Bool! = false
        
        @Optional.Value.String
        var memo: String?
    }
}

extension V2.Todo {
    class Constraint: NSObject, ConstraintSet {
        @CompositeFetchIndex
        var title = [AscendingIndex(\V2.Todo.$content), AscendingIndex(\V2.Todo.$isFinished)]
    }
}

typealias CurrentSchema = V2
typealias Todo = CurrentSchema.Todo
