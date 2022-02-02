//
//  PartialObjectTests.swift
//  
//
//  Created by ezou on 2021/10/22.
//

import CoreData
import Foundation
import XCTest

@testable import Crush

class PartialObjectTests: XCTestCase {
    class TestEntity: Entity {
        var integerValue = Value.Int64("integerValue")
        var stringValue = Value.String("stringValue")
    }

    func test_initWithPairs_shouldMergeIntoDictionary() {
        let sut = PartialObject<TestEntity>(
            EntityKeyValuePair(\.integerValue, 10)
        )
        let target = [
            "integerValue": Int64(10)
        ]
        XCTAssertEqual(sut.store as! [String: Int64], target)
    }

    func test_dynamicKeyPathUpdateValue_shouldWriteIntoStore() {
        let sut = PartialObject<TestEntity>()
        sut.integerValue = 10
        XCTAssertEqual(sut.store["integerValue"] as? Int64, 10)
    }

    func test_dynamicKeyPathUpdateValue_shouldReadFromStore() {
        let sut = PartialObject<TestEntity>(
            EntityKeyValuePair(\.integerValue, 10)
        )
        let target = sut.integerValue
        XCTAssertEqual(target, 10)
    }
}
