//
//  FethcedPropertyMigrationTests.swift
//  
//
//  Created by EZOU on 2023/4/26.
//

import CoreData
import Foundation
import XCTest

@testable import Crush

class AddFetchedPropertyTests: XCTestCase {
    func test_createProperty_shouldSetupNameAndFetchRequest() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let sut = AddFetchedProperty(name: "NAME", fetchRequest: fetchRequest)
        var callback: [EntityMigrationCallback] = []
        let description = sut.createProperty(callbackStore: &callback)
        XCTAssertTrue(description is NSFetchedPropertyDescription)
        XCTAssertEqual(description.name, "NAME")
        XCTAssertIdentical((description as! NSFetchedPropertyDescription).fetchRequest, fetchRequest)
    }
}

class UpdateFetchedPropertyTests: XCTestCase {
    func test_migrateProperty_shouldUpdateNameAndFetchRequest() throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let sut = UpdateFetchedProperty("origin", name: "NAME", fetchRequest: fetchRequest)
        let description = NSFetchedPropertyDescription()
        var callback: [EntityMigrationCallback] = []
        _ = try sut.migrateProperty(description, callbackStore: &callback)
        XCTAssertEqual(description.name, "NAME")
        XCTAssertIdentical(description.fetchRequest, fetchRequest)
    }
}
