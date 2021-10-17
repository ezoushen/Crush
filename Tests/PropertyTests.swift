//
//  PropertyTests.swift
//  
//
//  Created by ezou on 2021/10/9.
//

import XCTest

@testable import Crush

class PropertyTests: XCTestCase {
    func test_property_shouldBeRequired() {
        let property = Required.Value.Int16("property")
        let description = property.createPropertyDescription()
        XCTAssertFalse(description.isOptional, "property should be required")
    }

    func test_property_nameShouldEqualProperty() {
        let property = Required.Value.String("property")
        let description = property.createPropertyDescription()
        XCTAssertEqual(description.name, "property", "name should be property")
    }

    func test_propertyOption_shouldBeIndexedBySpotlight() {
        let property = Value.Int16("property", options: [PropertyOption.isIndexedBySpotlight(true)])
        let description = property.createPropertyDescription()
        XCTAssertTrue(description.isIndexedBySpotlight, "property should be indexed by spotlight")
    }

    func test_propertyOption_validationPredicateShouldBeSetProperly() {
        let predicate = PropertyCondition(largerThan: 0)
        let warning = "property should larger than zero"
        let property = Required.Value.Int16(
            "property",
            options: [PropertyOption.validationPredicatesWithWarnings([
                (predicate, warning)
            ])])
        let description = property.createPropertyDescription()
        XCTAssertEqual(description.validationPredicates.count, 1, "predicates size should be 1")
        XCTAssertEqual(description.validationPredicates.first, PropertyCondition(largerThan: 0), "predicate should be set properly")
        XCTAssertEqual(description.validationWarnings.count, 1, "warning size should be 1")
        XCTAssertEqual(description.validationWarnings.first as! String, warning, "warning should be set properly")
    }
}
