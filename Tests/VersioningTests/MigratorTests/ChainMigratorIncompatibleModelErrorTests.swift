//
//  File.swift
//  
//
//  Created by EZOU on 2023/4/1.
//

import CoreData
import Foundation
import XCTest

@testable import Crush

class EntityDiffTests: XCTestCase {
    func test_incompatible_shouldFindAddedRemovedAndIncompatiblePrperties() {
        let removedProperty = NSAttributeDescription()
        removedProperty.name = "removed"
        removedProperty.attributeType = .booleanAttributeType
        let addedProperty = NSAttributeDescription()
        addedProperty.name = "added"
        addedProperty.attributeType = .booleanAttributeType
        let incompatibleFromProperty = NSAttributeDescription()
        incompatibleFromProperty.name = "incompatible"
        incompatibleFromProperty.attributeType = .UUIDAttributeType
        let incompatibleToProperty = NSAttributeDescription()
        incompatibleToProperty.name = "incompatible"
        incompatibleToProperty.attributeType = .stringAttributeType
        let fromDescription = NSEntityDescription()
        fromDescription.name = "from"
        fromDescription.properties = [removedProperty, incompatibleFromProperty]
        let toDescription = NSEntityDescription()
        toDescription.name = "to"
        toDescription.properties = [addedProperty, incompatibleToProperty]

        let sut = ChainMigratorIncompatibleModelError.EntityDiff.incompatible(
            from: fromDescription, to: toDescription)

        XCTAssertEqual(sut.diff, .incompatible)
        XCTAssertEqual(sut.propertyDiffs, [
            .added(description: addedProperty),
            .removed(description: removedProperty),
            .incompatible(from: incompatibleFromProperty, to: incompatibleToProperty)
        ])
    }

    func test_modifier_shouldFoundDifferentModifiers() {
        let incompatibleFromProperty = NSAttributeDescription()
        incompatibleFromProperty.name = "incompatible"
        incompatibleFromProperty.attributeType = .stringAttributeType
        let incompatibleToProperty = NSAttributeDescription()
        incompatibleToProperty.name = "incompatible"
        incompatibleToProperty.attributeType = .stringAttributeType
        let fromDescription = NSEntityDescription()
        fromDescription.name = "from"
        fromDescription.versionHashModifier = "FROM"
        fromDescription.properties = [incompatibleFromProperty]
        let toDescription = NSEntityDescription()
        toDescription.name = "to"
        toDescription.versionHashModifier = "TO"
        toDescription.properties = [incompatibleToProperty]

        let sut = ChainMigratorIncompatibleModelError.EntityDiff.incompatible(
            from: fromDescription, to: toDescription)

        XCTAssertEqual(sut.diff, .modifier(from: "FROM", to: "TO"))
        XCTAssertTrue(sut.propertyDiffs.isEmpty)
    }
}
