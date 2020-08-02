//
//  Migrator.swift
//  Crush
//
//  Created by ezou on 2019/10/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public protocol DataMigrator {
    init(activeVersion: SchemaProtocol)
    var activeVersion: SchemaProtocol { get }
    func processStore(at url: URL) throws
}

enum MigratorError: Swift.Error {
    case incompatibleModels
}
