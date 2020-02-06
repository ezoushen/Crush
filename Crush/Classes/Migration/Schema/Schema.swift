//
//  Schema.swift
//  Crush
//
//  Created by ezou on 2019/10/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public protocol SchemaProtocol {
    init()
    var model: ObjectModel { get }
    var lastVersion: SchemaProtocol? { get }
}
