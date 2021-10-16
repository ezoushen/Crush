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
    let name = Optional.Value.String("name")
}

class A: C {
    let orderedList = Optional.Relation.ToOrderedMany<A, B>("orderedList")
    let unorderedList = Optional.Relation.ToMany<A, B>("unorderedList", inverse: \.owner)
}

class B: Entity {
    let owner = Optional.Relation.ToOne<B, A>("owner", inverse: \.orderedList)
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

class DataModelTests: XCTestCase {
    
    var sut: DataContainer!
    
    override func setUp() {
        sut = try! DataContainer.load(
            storage: .inMemory(),
            dataModel: .v_1)
    }
}
