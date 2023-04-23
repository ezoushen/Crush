//
//  DerivedAttributeTests.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation
import XCTest

@testable import Crush

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
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

    func test_derivedTransformable_derivationExpressionKeyPathShouldEqualToKeyPath() {
        @objc(_TtCFC10CrushTests21DerivedAttributeTests73test_derivedTransformable_derivationExpressionKeyPathShouldEqualToKeyPathFT_T_L_7Subject)
        final class Subject: NSObject, NSCoding, TransformableAttributeType {
            @objc var id: Int
            init(id: Int) { self.id = id }
            func encode(with coder: NSCoder) { coder.encode(id, forKey: "id") }
            required init?(coder: NSCoder) { id = Int(coder.decodeInt64(forKey: "id")) }
        }
        class TestEntity: Entity {
            @Optional
            var integer = Value.Int64("integer")
            @Optional
            var derivedInteger = Derived.Int64("derivedInteger", from: \TestEntity.integer)
            @Optional
            var property = Value.Transformable<Subject>("property")
            @Optional
            var derivedProperty = Derived.Transformable<Subject>("derivedProperty", from: \TestEntity.property)
            @Optional
            var entity = Relation.ToOne<TestEntity>("entity")
            @Optional
            var derivedEntityProperty = Derived.Transformable<Subject>("entity", from: \TestEntity.entity, property: \.property)
            @Optional
            var derivedEntityInteger = Derived.Int64("derivedEntityInteger", from: \TestEntity.entity, property: \.integer)
        }
        let entity = TestEntity()
        _ = {
            let description = entity.derivedProperty.createPropertyDescription() as! NSDerivedAttributeDescription
            XCTAssertEqual(description.attributeType, .transformableAttributeType)
            XCTAssertEqual(description.derivationExpression?.keyPath, "property")
        }()
        _ = {
            let description = entity.derivedInteger.createPropertyDescription()
            XCTAssertEqual(description.attributeType, Int64AttributeType.nativeType)
            XCTAssertEqual(description.derivationExpression?.keyPath, "integer")
        }()
        _ = {
            let description = entity.derivedEntityProperty.createPropertyDescription() as! NSDerivedAttributeDescription
            XCTAssertEqual(description.attributeType, .transformableAttributeType)
            XCTAssertEqual(description.derivationExpression?.keyPath, "entity.property")
        }()
        _ = {
            let description = entity.derivedEntityInteger.createPropertyDescription()
            XCTAssertEqual(description.attributeType, Int64AttributeType.nativeType)
            XCTAssertEqual(description.derivationExpression?.keyPath, "entity.integer")
        }()
    }
}
