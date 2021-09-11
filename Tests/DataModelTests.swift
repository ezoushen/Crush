//
//  DataModelTests.swift
//  Tests
//
//  Created by 沈昱佐 on 2020/3/16.
//  Copyright © 2020 ezoushen. All rights reserved.
//

import XCTest
import CoreData

@testable import Crush

class V1: SchemaOrigin {
    override var entities: [Entity.Type] {
        [
            People.self,
        ]
    }

    class People: EntityObject {
        var firstName = Optional.Value.String("firstName")
        var lastName = Required.Value.String("lastName")
    }
}

class PropertyTests: XCTestCase {
    func test_Property_shouldBeRequired() {
        let property = Required.Value.Int16("property")
        let description = property.emptyPropertyDescription()
        XCTAssert(description.isOptional == false, "property should be required")
    }

    func test_Property_nameShouldEqualProperty() {
        let property = Required.Value.String("property")
        let description = property.emptyPropertyDescription()
        XCTAssert(description.name == "property", "name should be property")
    }

    func test_Property_shouldBeTransient() {
        let property = Transient.Value.String("property")
        let description = property.emptyPropertyDescription()
        XCTAssert(description.isTransient == true, "property should be transient")
    }

    func test_Property_shouldBeIndexedBySpotlight() {
        let property = Value.Int16("property", options: [PropertyOption.isIndexedBySpotlight(true)])
        let description = property.emptyPropertyDescription()
        XCTAssert(description.isIndexedBySpotlight == true, "property should be indexed by spotlight")
    }

    func test_Property_validationPredicateShouldBeSetProperly() {
        let predicate = ValidationCondition(largerThan: 0)
        let warning = "property should larger than zero"
        let property = Required.Value.Int16(
            "property",
            options: [PropertyOption.validationPredicatesWithWarnings([
                (predicate, warning)
            ])])
        let description = property.emptyPropertyDescription()
        XCTAssert(description.validationPredicates.count == 1, "predicates size should be 1")
        XCTAssert(description.validationPredicates.first == ValidationCondition(largerThan: 0), "predicate should be set properly")
        XCTAssert(description.validationWarnings.count == 1, "warning size should be 1")
        XCTAssert(description.validationWarnings.first as! String == warning, "warning should be set properly")
    }
}

class AttributeTests: XCTestCase {
    func test_attribute_typeShouldBeString() {
        let attribute = Value.String("attribute")
        let description = attribute.emptyPropertyDescription() as! NSAttributeDescription
        XCTAssert(description.attributeType == .stringAttributeType)
    }

    func test_attribute_typeShouldBeBool() {
        let attribute = Value.Bool("attribute")
        let description = attribute.emptyPropertyDescription() as! NSAttributeDescription
        XCTAssert(description.attributeType == .booleanAttributeType)
    }

    func test_attribute_typeShouldBeInt16() {
        let attribute = Value.Int16("attribute")
        let description = attribute.emptyPropertyDescription() as! NSAttributeDescription
        XCTAssert(description.attributeType == .integer16AttributeType)
    }

    func test_attribute_typeShouldBeInt32() {
        let attribute = Value.Int32("attribute")
        let description = attribute.emptyPropertyDescription() as! NSAttributeDescription
        XCTAssert(description.attributeType == .integer32AttributeType)
    }

    func test_attribute_typeShouldBeInt64() {
        let attribute = Value.Int64("attribute")
        let description = attribute.emptyPropertyDescription() as! NSAttributeDescription
        XCTAssert(description.attributeType == .integer64AttributeType)
    }

    func test_attribute_typeShouldBeDecimal() {
        let attribute = Value.DecimalNumber("attribute")
        let description = attribute.emptyPropertyDescription() as! NSAttributeDescription
        XCTAssert(description.attributeType == .decimalAttributeType)
    }

    func test_attribute_typeShouldBeData() {
        let attribute = Value.Data("attribute")
        let description = attribute.emptyPropertyDescription() as! NSAttributeDescription
        XCTAssert(description.attributeType == .binaryDataAttributeType)
    }

    func test_attribute_typeShouldBeDate() {
        let attribute = Value.Date("attribute")
        let description = attribute.emptyPropertyDescription() as! NSAttributeDescription
        XCTAssert(description.attributeType == .dateAttributeType)
    }

    func test_attribute_typeShouldBeDouble() {
        let attribute = Value.Double("attribute")
        let description = attribute.emptyPropertyDescription() as! NSAttributeDescription
        XCTAssert(description.attributeType == .doubleAttributeType)
    }

    func test_attribute_typeShouldBeFloat() {
        let attribute = Value.Float("attribute")
        let description = attribute.emptyPropertyDescription() as! NSAttributeDescription
        XCTAssert(description.attributeType == .floatAttributeType)
    }

    func test_attribute_typeShouldBeUUID() {
        let attribute = Value.UUID("attribute")
        let description = attribute.emptyPropertyDescription() as! NSAttributeDescription
        XCTAssert(description.attributeType == .UUIDAttributeType)
    }

    func test_attribute_typeShouldBeCodableData() {
        struct Model: CodableProperty { }
        let attribute = Value.Codable<Model>("attribute")
        let description = attribute.emptyPropertyDescription() as! NSAttributeDescription
        XCTAssert(description.attributeType == .binaryDataAttributeType)
    }

    func test_attribute_typeShouldBeEnumString() {
        enum Model: String, Enumerator {
            typealias RawValue = String
            case dummy
        }
        let attribute = Value.Enum<Model>("attribute")
        let description = attribute.emptyPropertyDescription() as! NSAttributeDescription
        XCTAssert(description.attributeType == .stringAttributeType)
    }
}

class EntityTests: XCTestCase {
    
}
