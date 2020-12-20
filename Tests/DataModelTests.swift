//
//  DataModelTests.swift
//  Tests
//
//  Created by 沈昱佐 on 2020/3/16.
//  Copyright © 2020 ezoushen. All rights reserved.
//

import XCTest
@testable import Crush

class V1: SchemaOrigin {
    override var entities: [Entity.Type] {
        [
            People.self,
            Man.self
        ]
    }
    
    class People: AbstractEntityObject {
        class Index: NSObject, ConstraintSet {
            @FetchIndex
            var firstName = AscendingIndex(\V1.People.$firstName)
        }
        
        @Value.String("first_name")
        var firstName: String!
    }
    
    class Man: People {
        @Value.Int64("strength")
        var strength: Int64!
    }
}

class DataModelTests: XCTestCase {

    var sut: DataContainer!
    
    override func setUp() {
        sut = try! DataContainer(connection: Connection(type: .inMemory, name: "test", version: V1()))
    }

    override func tearDown() {
    }
    
    func test_DataModel() {
        let schema = V1()
        XCTAssert(schema.model.rawModel.entities.count == 2, "This Entity show ")
        
        let people = schema.model.rawModel.entitiesByName["People"]
        
        XCTAssert(people != nil)
        XCTAssert(people?.isAbstract == true)
        XCTAssert(people?.properties.count == 1)
        XCTAssert(people?.subentities.count == 1)
        
        let man = schema.model.rawModel.entitiesByName["Man"]
        
        XCTAssert(man != nil)
        XCTAssert(man?.isAbstract == false)
        XCTAssert(man?.properties.count == 2)
        XCTAssert(man?.superentity == people)
    }
    
    func test_Transaction_objectOnMainContextShouldBeRefreshedAfterCommitted() {
        let person: V1.People.ReadOnly = try! sut.startTransaction().sync { context in
            let people = context.create(entiy: V1.People.self)
            people.firstName = "first name"
            try context.commit()
            return people
        }
        
        try! sut.startTransaction().edit(person).sync { context, person in
            person.firstName = "FIRST NAME"
            try context.commit()
        }
        
        XCTAssert(person.firstName == "FIRST NAME")
    }
}
