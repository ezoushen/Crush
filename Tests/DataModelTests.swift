//
//  DataModelTests.swift
//  Tests
//
//  Created by 沈昱佐 on 2020/3/16.
//  Copyright © 2020 ezoushen. All rights reserved.
//

import CoreData
import XCTest

@testable import Crush

class C: Entity {
    let name = Value.String("name")
}

class A: C {
    @Optional
    var orderedList = Relation.ToOrdered<B>("orderedList")

    @Optional
    var unorderedList = Relation.ToMany<B>("unorderedList")
}

class B: Entity {
    @Optional
    var owner = Relation.ToOne<A>("owner", inverse: \.orderedList)
}

class Entity_Root: Entity {
    @Optional
    var attribute_optional = Value.Bool("optional_attribute")
}

class Entity_1: Entity {
    let attribute_required = Value.String("required_attribute")

    let attribute_string = Value.String("string_value")
    let atrribute_integer16 = Value.Int16("attribute_integer16")
    let atrribute_integer32 = Value.Int16("attribute_integer32")
    let atrribute_integer64 = Value.Int16("attribute_integer64")
}

extension DataModel {
    static var v_1: DataModel {
        DataModel("V1") {
            EntityDescription<C>(.embedded)
            EntityDescription<A>(.concrete)
            EntityDescription<B>(.concrete)
        }
    }
}

extension MigrationChain {
    static var `default`: MigrationChain = MigrationChain {
        ModelMigration("V1") {
            AddEntity("A") {
                AddAttribute("name", type: String.self, isOptional: true)
                AddRelationship("orderedList", toMany: "B", inverse: "owner", isOptional: true, isOrdered: true)
                AddRelationship("unorderedList", toMany: "B", isOptional: true)
            }
            AddEntity("B") {
                AddRelationship("owner", toOne: "A", inverse: "orderedList", isOptional: true)
            }
        }
    }
}

extension MigrationPolicy {
    static func waterDoChain() -> MigrationPolicy {
        .chain(.default)
    }
}

class DataModelTests: XCTestCase {
    
    lazy var sut: DataContainer! = try! DataContainer.load(
        storage: .inMemory(),
        dataModel: .v_1,
        migrationPolicy: .waterDoChain())
    
    override func setUp() {
//        try! sut.rebuildStorage()
    }

    func test_myTest() {
        sut.startSession().sync { context in
            let a = context.create(entity: A.self)
            
        }
//        print(DataModel.v_1.managedObjectModel)
    }
}
