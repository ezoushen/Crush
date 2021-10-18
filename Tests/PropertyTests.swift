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
        let property = Value.Int16("property")
        let description = property.createPropertyDescription()
        XCTAssertFalse(description.isOptional, "property should be required")
    }

    func test_property_nameShouldEqualProperty() {
        let property = Value.String("property")
        let description = property.createPropertyDescription()
        XCTAssertEqual(description.name, "property", "name should be property")
    }

    func test_propertyOption_shouldBeIndexedBySpotlight() {
        let property = IndexedBySpotlight(wrappedValue: Value.Int16("property"), true)
        let description = property.createPropertyDescription()
        XCTAssertTrue(description.isIndexedBySpotlight, "property should be indexed by spotlight")
    }
}
