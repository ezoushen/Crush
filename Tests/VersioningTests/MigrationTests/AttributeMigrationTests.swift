//
//  AttributeMigrationTests.swift
//  
//
//  Created by ezou on 2021/10/23.
//

import CoreData
import Foundation
import XCTest

@testable import Crush

class AddAttributeMigrationTests: XCTestCase {
    let sut = AddAttribute("name", type: String.self, isOptional: false, isTransient: true)
    
    func test_createProperty_shouldSetName() {
        var store: [EntityMigrationCallback] = []
        let description = sut.createProperty(callbackStore: &store)
        XCTAssertEqual(description.name, sut.name)
    }
    
    func test_createProperty_shouldSetIsOptional() {
        var store: [EntityMigrationCallback] = []
        let description = sut.createProperty(callbackStore: &store)
        XCTAssertEqual(description.isOptional, sut.isOptional)
    }
    
    func test_createProperty_shouldSetIsTransient() {
        var store: [EntityMigrationCallback] = []
        let description = sut.createProperty(callbackStore: &store)
        XCTAssertEqual(description.isTransient, sut.isTransient)
    }
    
    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    func test_createProperty_shouldBeDerived() {
        let sut = AddAttribute("name", type: String.self, isOptional: false, derivedExpression: NSExpression(format: "another"))
        var store: [EntityMigrationCallback] = []
        let description = sut.createProperty(callbackStore: &store)
        XCTAssertTrue(description is NSDerivedAttributeDescription)
    }
    
    func test_createPropertyMapping_shouldSetName() {
        let mapping = sut.createPropertyMapping(from: nil, to: nil, of: NSEntityDescription())
        XCTAssertEqual(mapping?.name, sut.name)
    }
}

class UpdateAttributeTests: XCTestCase {
    
}
