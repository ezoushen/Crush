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
    let orderedList = Optional.Relation.ToOrderedMany<A, B>("orderedList", inverse: \.owner, options: [RelationshipOption.unidirectionalInverse])
    let unorderedList = Optional.Relation.ToMany<A, B>("unorderedList")
}
class B: Entity {
    let owner = Optional.Relation.ToOne<B, A>("owner", inverse: \.unorderedList)
}

class DataModelTests: XCTestCase {
    
    var sut: DataContainer!
    
    override func setUp() {
        sut = try! DataContainer(
            storage: Storage.inMemory(),
            dataModel: DataModel("V1", descriptions: [
                EntityDescription(type: C.self, inheritance: .abstract),
                EntityDescription(type: A.self, inheritance: .concrete),
                EntityDescription(type: B.self, inheritance: .concrete),
            ]))
    }
}
