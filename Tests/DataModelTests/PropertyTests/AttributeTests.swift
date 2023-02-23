//
//  AttributeTests.swift
//  
//
//  Created by ezou on 2021/10/9.
//

import XCTest
import CoreData

@testable import Crush

class AttributeTests: XCTestCase {
    func test_attributeString_typeShouldBeString() {
        let attribute = Value.String("attribute")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.attributeType, .stringAttributeType)
    }
    
    func test_attributeStringWithDefaultValue_defaultValueShouldBeString() {
        let attribute = Default(wrappedValue: Value.String("attribute"), "string")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.defaultValue as? String, "string")
    }

    func test_attributeBool_typeShouldBeBool() {
        let attribute = Value.Bool("attribute")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.attributeType, .booleanAttributeType)
    }
    
    func test_attributeBoolWithDefaultValue_defaultValueShouldBeTrue() {
        let attribute = Default(wrappedValue: Value.Bool("attribute"), true)
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.defaultValue as? Bool, true)
    }

    func test_attributeInt16_typeShouldBeInt16() {
        let attribute = Value.Int16("attribute")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.attributeType, .integer16AttributeType)
    }
    
    func test_attributeInt16WithDefaultValue_defaultValueShouleBe16() {
        let attribute = Default(wrappedValue: Value.Int16("attribute"), 16)
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.defaultValue as? Int16, 16)
    }

    func test_attributeInt32_typeShouldBeInt32() {
        let attribute = Value.Int32("attribute")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.attributeType, .integer32AttributeType)
    }
    
    func test_attributeInt32WithDefaultValue_defaultValueShouldBe32() {
        let attribute = Default(wrappedValue: Value.Int32("attribute"), 32)
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.defaultValue as? Int32, 32)
    }

    func test_attributeInt64_typeShouldBeInt64() {
        let attribute = Value.Int64("attribute")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.attributeType, .integer64AttributeType)
    }
    
    func test_attributeInt64WithDefaultValue_defaultValueShouldBe64() {
        let attribute = Default(wrappedValue: Value.Int64("attribute"), 64)
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.defaultValue as? Int64, 64)
    }

    func test_attributeDecimal_typeShouldBeDecimal() {
        let attribute = Value.DecimalNumber("attribute")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.attributeType, .decimalAttributeType)
    }
    
    func test_attributeDecimalWithDefaultValue_defaultValueShouldBe10() {
        let attribute = Default(wrappedValue: Value.DecimalNumber("attribute"), 10)
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.defaultValue as? NSDecimalNumber, 10)
    }

    func test_attributeData_typeShouldBeData() {
        let attribute = Value.Data("attribute")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.attributeType, .binaryDataAttributeType)
    }
    
    func test_attributeDataWithDefaultValue_defaultValueShouldBeData() {
        let data = "DATA".data(using: .utf8)
        let attribute = Default(wrappedValue: Value.Data("attribute"), data)
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.defaultValue as? Data, data)
    }

    func test_attributeDate_typeShouldBeDate() {
        let attribute = Value.Date("attribute")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.attributeType, .dateAttributeType)
    }
    
    func test_attributeDateWithDefaultValue_defaultValueShouldBeNow() {
        let now = Date()
        let attribute = Default(wrappedValue: Value.Date("attribute"), now)
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.defaultValue as? Date, now)
    }

    func test_attributeDouble_typeShouldBeDouble() {
        let attribute = Value.Double("attribute")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.attributeType, .doubleAttributeType)
    }
    
    func test_attributeDoubleWithDefaultValue_defaultValueShouldBe10() {
        let attribute = Default(wrappedValue: Value.Double("attribute"), 10.0)
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.defaultValue as? Double, 10.0)
    }

    func test_attributeFloat_typeShouldBeFloat() {
        let attribute = Value.Float("attribute")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.attributeType, .floatAttributeType)
    }
    
    func test_attributeFloatWithDefaultValue_defaultValueShouldBe10() {
        let attribute = Default(wrappedValue: Value.Float("attribute"), 10.0)
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.defaultValue as? Float, 10.0)
    }

    func test_attributeUUID_typeShouldBeUUID() {
        let attribute = Value.UUID("attribute")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.attributeType, .UUIDAttributeType)
    }
    
    func test_attributeUUIDWithDefaultValue_defaultValueShouldBeUUID() {
        let uuid = UUID()
        let attribute = Default(wrappedValue: Value.UUID("attribute"), uuid)
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.defaultValue as? UUID, uuid)
    }

    func test_attributeCodable_typeShouldBeCodableData() {
        struct Model: CodableAttributeType { }
        let attribute = Value.Codable<Model>("attribute")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.attributeType, .binaryDataAttributeType)
    }
    
    func test_attributeCodableWithDefaultValue_defaultValueShouldBeCodable() {
        struct Model: CodableAttributeType {
            let value: Int
        }
        let model = Model(value: 100)
        let attribute = Default(wrappedValue: Value.Codable<Model>("attribute"), model)
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.defaultValue as? Data, model.data)
    }

    func test_attributeEnum_typeShouldBeEnumString() {
        enum Model: String, EnumerableAttributeType {
            typealias RawValue = String
            case dummy
        }
        let attribute = Value.Enum<Model>("attribute")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.attributeType, .stringAttributeType)
    }
    
    func test_attributeEnumWithDefaultValue_defaultValueShouldBeStringDummy() {
        enum Model: String, EnumerableAttributeType {
            typealias RawValue = String
            case dummy
        }
        let attribute = Default(wrappedValue: Value.Enum<Model>("attribute"), .dummy)
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.defaultValue as? String, Model.dummy.rawValue)
    }

    func test_attributeOption_validationsShouldBeSet() {
        let predicate = PropertyCondition<Bool>(format: "SELF == NO")
        let warning = "warning"
        let attribute = Validation(wrappedValue: Value.Bool("attribute"), predicate, warning: "warning")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertEqual(description.validationPredicates, [predicate])
        XCTAssertEqual(description.validationWarnings as! [String], [warning])
    }
    
    func test_attributeOption_allowsExternalBinaryDataStorageShouldBeTrue() {
        let attribute = ExternalBinaryDataStorage(wrappedValue: Value.Bool("attribute"))
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertTrue(description.allowsExternalBinaryDataStorage)
    }
    
    func test_attributeOption_allowsExternalBinaryDataStorageShouldBeFalse() {
        let attribute = Value.Bool("attribute")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertFalse(description.allowsExternalBinaryDataStorage)
    }

    @available(iOS 13.0, *)
    func test_attributeOption_preservesValueInHistoryOnDeletionShouldBeTrue() {
        let attribute = PreservesValueInHistoryOnDeletion(wrappedValue: Value.Bool("attribute"))
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertTrue(description.preservesValueInHistoryOnDeletion)
    }

    @available(iOS 13.0, *)
    func test_attributeOption_preservesValueInHistoryOnDeletionShouldBeFalse() {
        let attribute = Value.Bool("attribute")
        let description = attribute.createPropertyDescription() as! NSAttributeDescription
        XCTAssertFalse(description.preservesValueInHistoryOnDeletion)
    }
}
