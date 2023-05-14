//
//  InsertBuilderTests.swift
//  
//
//  Created by EZOU on 2023/5/14.
//

import Foundation
import XCTest

@testable import Crush

class InsertBuilderTests: XCTestCase {
    class TestEntity: Entity {
        @Optional
        var name = Value.String("name")
    }

    var container: DataContainer!

    override func setUpWithError() throws {
        try container = .load(
            storages: .sqliteInMemory(),
            dataModel: DataModel(
                name: "V1", [TestEntity()]
            )
        )
    }

    @available(iOS 14.0, watchOS 7.0, macOS 11.0, tvOS 14.0, *)
    func test_batchInsertWithObjectHandler_shouldInsert() throws {
        let sut = container.insert(for: TestEntity.self)
        let names = ["A", "B", "C"]
        let results = try sut
            .objects(from: names) { string, entity in
                entity.name = string
            }
            .exec()
        let objects: [TestEntity.ReadOnly?] = container.load(objectIDs: results)
        let insertedNames = objects.compactMap { $0?.name }
        XCTAssertEqual(insertedNames, names)
    }

    @available(iOS 14.0, watchOS 7.0, macOS 11.0, tvOS 14.0, *)
    func test_batchInsertWithDictionaryHandler_shouldInsert() throws {
        let sut = container.insert(for: TestEntity.self)
        let names = ["A", "B", "C"]
        let results = try sut
            .objects(from: names) { (string: String, dictionary: NSMutableDictionary) in
                dictionary.setValue(string, forKey: "name")
            }
            .exec()
        let objects: [TestEntity.ReadOnly?] = container.load(objectIDs: results)
        let insertedNames = objects.compactMap { $0?.name }
        XCTAssertEqual(insertedNames, names)
    }

    func test_batchInsertWithDictionary_shoulInsert() throws {
        let sut = container.insert(for: TestEntity.self)
        let names = ["A", "B", "C"]
        let results = try sut
            .objects(contentsOf: [["name": "A"], ["name": "B"], ["name": "C"]])
            .exec()
        let objects: [TestEntity.ReadOnly?] = container.load(objectIDs: results)
        let insertedNames = objects.compactMap { $0?.name }
        XCTAssertEqual(insertedNames, names)
    }

    func test_batchInsertWithObject_shouldInsert() throws {
        let sut = container.insert(for: TestEntity.self)
        let names = ["A", "B", "C"]
        let results = try sut
            .object(["name": "A"])
            .object(["name": "B"])
            .object(["name": "C"])
            .exec()
        let objects: [TestEntity.ReadOnly?] = container.load(objectIDs: results)
        let insertedNames = objects.compactMap { $0?.name }
        XCTAssertEqual(insertedNames, names)
    }
}
