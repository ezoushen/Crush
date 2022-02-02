//
//  DerivedAttributeTests.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation
import XCTest

import Crush

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
class DerivedAttributeTests: XCTestCase {
    class Entity_A: Entity {
        var attribute = Value.String("attribute")
        var relationship = Relation.ToMany<Entity_B>("relationship")
    }

    class Entity_B: Entity { }

    func test_expression_timestampShouldBeNow() {
        let sut = Derived.Date("timestamp")
        XCTAssertEqual(sut.expression, NSExpression(format: "now()"))
    }

    func test_expression_shouldBeAnotherPropertyName() {
        let sut = Derived.String("derivedAttribute", from: \Entity_A.attribute)
        XCTAssertEqual(sut.expression, NSExpression(format: "attribute"))
    }

    func test_expression_derivedStringMappingCanonical() {
        let sut = Derived.String("derivedAttribute", from: \Entity_A.attribute, mapping: .canonical)
        XCTAssertEqual(sut.expression, NSExpression(format: "canonical:(attribute)"))
    }

    func test_expression_derivedStringMappingUppercase() {
        let sut = Derived.String("derivedAttribute", from: \Entity_A.attribute, mapping: .uppercase)
        XCTAssertEqual(sut.expression, NSExpression(format: "uppercase:(attribute)"))
    }

    func test_expression_derivedStringMappingLowercase() {
        let sut = Derived.String("derivedAttribute", from: \Entity_A.attribute, mapping: .lowercase)
        XCTAssertEqual(sut.expression, NSExpression(format: "lowercase:(attribute)"))
    }

    func test_expression_derivedAggregationCount() {
        let sut = Derived.Int16("derivedRelationship", from: \Entity_A.relationship, aggregation: .count)
        XCTAssertEqual(sut.expression, NSExpression(format: "relationship.@count"))
    }
}
