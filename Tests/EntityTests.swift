//
//  EntityTests.swift
//  
//
//  Created by ezou on 2021/10/21.
//

import CoreData
import XCTest
import Foundation

@testable import Crush

class EntityTests: XCTestCase {
    func test_hashValue_shouldOnlyEffectedByClassType() {
        class TestEntity: Entity { }
        let sut = TestEntity()
        let target = TestEntity()
        XCTAssertEqual(sut.hashValue, target.hashValue)
    }

    func test_equatable_shouldConsiderHashValueOnly() {
        class TestEntity: Entity { }
        let sut = TestEntity()
        let target = TestEntity()
        XCTAssertEqual(sut, target)
    }

    func test_fetchKey_shouldEqualToClassName() {
        class TestEntity: Entity { }
        XCTAssertEqual(TestEntity.fetchKey, "TestEntity")
    }

    func test_createEntityDescription_shouldReturnNilForEmbeddedEntity() {
        class TestEntity: Entity { }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(type(of: sut)): .embedded
        ]
        XCTAssertNil(sut.createEntityDescription(inhertanceData: data))
    }

    func test_createEntityDescription_shouldReturnNilWhileInheritanceTypeUndefined() {
        class TestEntity: Entity { }
        let sut = TestEntity()
        let result = sut.createEntityDescription(inhertanceData: [:])
        XCTAssertNil(result?.propertiesByName["value"])
    }

    func test_createEntityDescription_shouldReturnAbstractEntityDescription() {
        class TestEntity: Entity { }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(type(of: sut)): .abstract
        ]
        let result = sut.createEntityDescription(inhertanceData: data)?.isAbstract
        XCTAssertTrue(result == true)
    }

    func test_createEntityDescription_shouldReturnConcreteEntityDescription() {
        class TestEntity: Entity { }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(type(of: sut)): .concrete
        ]
        let result = sut.createEntityDescription(inhertanceData: data)?.isAbstract
        XCTAssertTrue(result == false)
    }

    func test_createEntityDescription_nameShouldEqualToFetchKey() {
        class TestEntity: Entity { }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(type(of: sut)): .concrete
        ]
        let result = sut.createEntityDescription(inhertanceData: data)
        XCTAssertEqual(result?.name, TestEntity.fetchKey)
    }

    func test_createEntityDescription_attriuteShouldBeDefinedInProperties() {
        class TestEntity: Entity {
            var value = Value.Int32("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(type(of: sut)): .concrete
        ]
        let result = sut.createEntityDescription(inhertanceData: data)
        XCTAssertNotNil(result?.propertiesByName["value"])
    }

    func test_createEntityDescription_relationshipShouldBeDefinedInProperties() {
        class TestEntity: Entity {
            var value = Relation.ToOne<TestEntity>("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(type(of: sut)): .concrete
        ]
        let result = sut.createEntityDescription(inhertanceData: data)
        XCTAssertNotNil(result?.propertiesByName["value"])
    }

    func test_createEntityDescription_derivedAttributeShouldBeDefinedInProperties() {
        class TestEntity: Entity {
            var value = Value.Int64("value")
            var derived = Derived.Int64("derived", from: \TestEntity.value)
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(type(of: sut)): .concrete
        ]
        let result = sut.createEntityDescription(inhertanceData: data)
        XCTAssertNotNil(result?.propertiesByName["derived"])
    }

    func test_craeteEntityDescription_embeddedPropertyShouldNotBeParentEntity() {
        let result = createInheritedEntityDescription(.embedded)
        XCTAssertNil(result?.superentity)
    }

    func test_createEntityDescription_embeddedPropertyShouldBeDefinedInProperties() {
        let result = createInheritedEntityDescription(.embedded)
        XCTAssertNotNil(result?.propertiesByName["parentValue"])
    }

    func test_createEntityDescription_superEntityShouldNotBeNil() {
        let result = createInheritedEntityDescription(.abstract)
        XCTAssertNotNil(result?.superentity)
    }

    private func createInheritedEntityDescription(_ type: EntityInheritance) -> NSEntityDescription? {
        class ParentEntity: Entity {
            var parentValue = Value.Int64("parentValue")
        }
        class TestEntity: ParentEntity { }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(ParentEntity.self): type,
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        _ = ParentEntity().createEntityDescription(inhertanceData: data)
        return sut.createEntityDescription(inhertanceData: data)
    }

    func test_createEntityDescription_shouldIncludeIndexes() {
        class TestEntity: Entity {
            @Indexed
            var value = Value.Int64("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(inhertanceData: data)
        XCTAssertEqual(result?.indexes.first?.name, "value")
    }

    func test_createEntityDescription_indexedEntityShouldBeTestEntity() {
        class TestEntity: Entity {
            @Indexed
            var value = Value.Int16("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(inhertanceData: data)
        XCTAssertEqual(result?.indexes.first?.entity, result)
    }

    func test_createEntityDescription_indexPropertyNameShouldMatchTheProperty() {
        class TestEntity: Entity {
            @Indexed
            var value = Value.Int16("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(inhertanceData: data)
        XCTAssertEqual(result?.indexes.first?.elements.first?.propertyName, "value")
    }

    func test_createEntityDescription_indexedTypeShouldBeRTree() {
        class TestEntity: Entity {
            @Indexed(collationType: .rTree)
            var value = Value.Int16("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(inhertanceData: data)
        XCTAssertEqual(result?.indexes.first?.elements.first?.collationType, .rTree)
    }

    func test_createEntityDescription_indexesShouldBeGroupedByName() {
        class TestEntity: Entity {
            @Indexed("composite")
            var value = Value.Int16("value")
            @Indexed("composite")
            var value2 = Value.Int16("value2")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(inhertanceData: data)
        XCTAssertEqual(result?.indexes.first?.elements.count, 2)
    }

    func test_createEntityDescription_partialIndexShouldHavePredicate() {
        class TestEntity: Entity {
            @Indexed(predicate: NSPredicate(format: "value == 0"))
            var value = Value.Int16("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(inhertanceData: data)
        XCTAssertEqual(result?.indexes.first?.partialIndexPredicate, \TestEntity.value == 0)
    }

    func test_createEntityDescription_uniquenessConstraintsShouldBeSet() {
        class TestEntity: Entity {
            @Unique
            var value = Value.Int16("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(inhertanceData: data)
        XCTAssertEqual(result?.uniquenessConstraints as! [[String]], [["value"]])
    }

    func test_createEntityDescription_uniquenessConstraintsShouldBeGroupedByName() {
        class TestEntity: Entity {
            @Unique("composite")
            var value = Value.Int16("value")
            @Unique("composite")
            var value2 = Value.Int16("value2")
            @Unique
            var value3 = Value.Int16("value3")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityInheritance] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(inhertanceData: data)
        XCTAssertEqual(Set(result?.uniquenessConstraints as! [[String]]), [["value", "value2"], ["value3"]])
    }
}
