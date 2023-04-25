//
//  UpdateBuilderTests.swift
//  
//
//  Created by EZOU on 2022/7/22.
//

import Foundation
import XCTest

@testable import Crush

class UpdateBuilderTests: XCTestCase {
    
    class TestEntity: Entity {
        var intValue = Value.Int64("intValue")
        var entity = Relation.ToOne<TestEntity>("entity")
    }
    
    var sut: DataContainer!
    
    override func setUpWithError() throws {
        sut = try?.load(storages: .sqliteInMemory(), dataModel: .init(name: "DataModel", [TestEntity()]))
    }
    
    func test_updateIntValue_shouldUpdateAttribute() throws {
        let entity: TestEntity.ReadOnly = try sut.startSession().sync { context in
            let entity = context.create(entity: TestEntity.self)
            entity.intValue = 0
            try context.commit()
            return entity
        }
        
        let ids = try sut
            .update(for: TestEntity.self)
            .update(\.intValue, value: 10)
            .exec()
        
        XCTAssertEqual(ids, [entity.objectID])
        XCTAssertEqual(entity.intValue, 10)
    }
}
