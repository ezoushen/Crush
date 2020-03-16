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
    class People: EntityObject {
        @Value.String
        var firstName: String
        
        @Value.String
        var lastName: String
    }
}

class DataModelTests: XCTestCase {

    var sut: DataContainer!
    
    override func setUp() {
        sut = try! DataContainer(connection: Connection(type: .inMemory, name: "test", version: V1()))
    }

    override func tearDown() {
    }
}
