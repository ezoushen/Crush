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

class V2: SchemaOrigin {
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
        
        @UniqueConstraint
        var context = \V2.Todo.$content
    }
}

class V3: SchemaOrigin {
    class Titleable: EntityObject {
        @Value.String
        var title: String! = "TITLE"
    }
    
    class Todo: Titleable {
        @Value.String
        var content: String! = ""
        
        @Value.Date
        var dueDate: Date! = Date()
        
        @Value.Bool
        var isFinished: Bool! = false
        
        @Optional.Value.String
        var memo: String?
    }
    
    class List: Titleable {
        @Value.String
        var alias: String! = "ALIAS"
    }
}

typealias CurrentSchema = V3
typealias Todo = CurrentSchema.Todo
