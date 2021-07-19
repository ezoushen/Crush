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
        ]
    }

    class People: EntityObject {
        var firstName = Value.String("firstName")
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
        sut.startTransaction().sync { context in
            let people = context.create(entity: V1.People.self)
            people.firstName = "ASD"
            try! context.commitAndWait()
        }

        let people = sut.fetch(for: V1.People.self)
            .where(\V1.People.firstName == "ASD")
            .findOne()
        print(people?.firstName)
    }
}
