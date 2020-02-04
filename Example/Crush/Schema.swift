//
//  Schema.swift
//  Crush_Example
//
//  Created by 沈昱佐 on 2020/1/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Crush

class V1: Schema<FirstVersion> {
    class Todo: EntityObject {
        @Value.String
        var title: String = ""
        
        @Value.Date
        var dueDate: Date = Date()
        
        @Value.Bool
        var isFinished: Bool = false
        
        @Optional.Value.String
        var memo: String?
    }
}

class V2: Schema<V1> {
    class Todo: EntityObject {
        @Value.String(options: [PropertyOption.mapping(\V1.Todo.$title)])
        var content: String = ""
        
        @Value.Date
        var dueDate: Date = Date()
        
        @Value.Bool
        var isFinished: Bool = false
        
        @Optional.Value.String
        var memo: String?
    }
}

typealias CurrentSchema = V2
typealias Todo = CurrentSchema.Todo
