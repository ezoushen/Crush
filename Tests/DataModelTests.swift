//
//  DataModelTests.swift
//  Tests
//
//  Created by 沈昱佐 on 2020/3/16.
//  Copyright © 2020 ezoushen. All rights reserved.
//

import XCTest

@testable import Crush

class TestSchema: SchemaOrigin {
    override var descriptions: [EntityDescription] {
        [
            EntityDescription(type: A.self, inheritance: .concrete),
            EntityDescription(type: B.self, inheritance: .concrete),
        ]
    }
    
    class A: Entity {
        required init() { }
        let orderedList = Optional.Relation.ToOrderedMany<A, B>("orderedList")
        let unorderedList = Optional.Relation.ToMany<A, B>("unorderedList", inverse: \.owner, options: [RelationshipOption.unidirectionalInverse])
    }
    class B: Entity {
        required init() { }
        let owner = Optional.Relation.ToOne<B, A>("owner", inverse: \.orderedList)
    }
}

class DataModelTests: XCTestCase {
    
    var sut: DataContainer!
    
    override func setUp() {
        sut = try! DataContainer(connection: Connection(type: .inMemory, name: "Test", version: TestSchema()))
    }
    
    func test_myTest() {
        
        let a = sut.startTransaction().sync {
            context -> TestSchema.A.ManagedObject in

            let a = context.create(entity: TestSchema.A.self)
            let b1 = context.create(entity: TestSchema.B.self)
            let b2 = context.create(entity: TestSchema.B.self)
            a.orderedList.append(b1)
            a.unorderedList.insert(b2)

            try! context.commitAndWait()
            
            return a
        }
        
        print(a.orderedList)
        print(a.unorderedList)
    }
}
