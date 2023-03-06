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

    var cache = EntityCache()

    override func setUp() {
        cache = .init()
    }

    override func tearDown() {
        cache.clean()
    }

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
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(type(of: sut)): .embedded
        ]
        XCTAssertNil(sut.createEntityDescription(abstractionData: data, cache: cache))
    }

    func test_createEntityDescription_shouldReturnNilWhileAbstractionUndefined() {
        class TestEntity: Entity { }
        let sut = TestEntity()
        let result = sut.createEntityDescription(abstractionData: [:], cache: cache)
        XCTAssertNil(result?.propertiesByName["value"])
    }

    func test_createEntityDescription_shouldReturnAbstractEntityDescription() {
        class TestEntity: Entity { }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(type(of: sut)): .abstract
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)?.isAbstract
        XCTAssertTrue(result == true)
    }

    func test_createEntityDescription_shouldReturnConcreteEntityDescription() {
        class TestEntity: Entity { }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(type(of: sut)): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)?.isAbstract
        XCTAssertTrue(result == false)
    }

    func test_createEntityDescription_nameShouldEqualToFetchKey() {
        class TestEntity: Entity { }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(type(of: sut)): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)
        XCTAssertEqual(result?.name, TestEntity.fetchKey)
    }

    func test_createEntityDescription_attriuteShouldBeDefinedInProperties() {
        class TestEntity: Entity {
            var value = Value.Int32("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(type(of: sut)): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)
        XCTAssertNotNil(result?.propertiesByName["value"])
    }

    func test_createEntityDescription_relationshipShouldBeDefinedInProperties() {
        class TestEntity: Entity {
            var value = Relation.ToOne<TestEntity>("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(type(of: sut)): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)
        XCTAssertNotNil(result?.propertiesByName["value"])
    }

    @available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
    func test_createEntityDescription_derivedAttributeShouldBeDefinedInProperties() {
        class TestEntity: Entity {
            var value = Value.Int64("value")
            var derived = Derived.Int64("derived", from: \TestEntity.value)
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(type(of: sut)): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)
        XCTAssertNotNil(result?.propertiesByName["derived"])
    }

    func test_createEntityDescriptionFetchedProperty_shouldBeDefinedWithFetchRequest() {
        class TestEntity: Entity {
            var value = Value.Int64("value")
            var fetched = Fetched<TestEntity>("fetched") { $0.where(\.value == 1) }
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)
        let description = result?.propertiesByName["fetched"] as! NSFetchedPropertyDescription
        XCTAssertNotNil(description.fetchRequest)
    }

    func test_createEntityDescription_embeddedPropertyShouldNotBeParentEntity() {
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
    
    class ParentEntity: Entity {
        var parentValue = Value.Int64("parentValue")
    }
    
    class TestEntity: ParentEntity { }

    private func createInheritedEntityDescription(_ type: EntityAbstraction) -> NSEntityDescription? {
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(ParentEntity.self): type,
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        _ = ParentEntity().createEntityDescription(abstractionData: data, cache: cache)
        return sut.createEntityDescription(abstractionData: data, cache: cache)
    }

    func test_createEntityDescription_shouldIncludeIndexes() {
        class TestEntity: Entity {
            @Indexed
            var value = Value.Int64("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)
        XCTAssertEqual(result?.indexes.first?.name, "value")
    }

    func test_createEntityDescription_indexedEntityShouldBeTestEntity() {
        class TestEntity: Entity {
            @Indexed
            var value = Value.Int16("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)
        XCTAssertEqual(result?.indexes.first?.entity, result)
    }

    func test_createEntityDescription_indexPropertyNameShouldMatchTheProperty() {
        class TestEntity: Entity {
            @Indexed
            var value = Value.Int16("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)
        XCTAssertEqual(result?.indexes.first?.elements.first?.propertyName, "value")
    }

    func test_createEntityDescription_indexedTypeShouldBeRTree() {
        class TestEntity: Entity {
            @Indexed(collationType: .rTree)
            var value = Value.Int16("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)
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
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)
        XCTAssertEqual(result?.indexes.first?.elements.count, 2)
    }

    func test_createEntityDescription_partialIndexShouldHavePredicate() {
        class TestEntity: Entity {
            @Indexed(predicate: NSPredicate(format: "value == 0"))
            var value = Value.Int16("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)
        XCTAssertEqual(result?.indexes.first?.partialIndexPredicate, \TestEntity.value == 0)
    }

    func test_createEntityDescription_indexesShouldBeGroupedByNameMultipleTimes() {
        class TestEntity: Entity {
            @Indexed("composite")
            @Indexed
            var value = Value.Int16("value")
            @Indexed("composite")
            var value2 = Value.Int16("value2")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)
        let indexes = result?.indexes.sorted { $0.elements.count < $1.elements.count } ?? []
        XCTAssertEqual(indexes.count, 2)
        XCTAssertEqual(indexes.first?.elements.count, 1)
        XCTAssertEqual(indexes.last?.elements.count, 2)
    }

    func test_createEntityDescription_indexesShouldBeInheritedAccordingToTargetEntityName() {
        class TestEntity: Entity {
            @Indexed("child", target: ChildEntity.self)
            var value = Value.Int16("value")
            @Indexed(target: AnotherChildEntity.self)
            var value2 = Value.Int16("value2")
        }
        class AnotherChildEntity: TestEntity { }
        class ChildEntity: TestEntity {
            @Indexed("child")
            var value3 = Value.Int16("value3")
        }
        let sut = ChildEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(TestEntity.self): .embedded,
            ObjectIdentifier(ChildEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)
        let indexes = result?.indexes ?? []
        XCTAssertEqual(indexes.count, 1)
        XCTAssertEqual(indexes.first?.elements.count, 2)
    }

    func test_createEntityDescription_uniquenessConstraintsShouldBeSet() {
        class TestEntity: Entity {
            @Unique
            var value = Value.Int16("value")
        }
        let sut = TestEntity()
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)
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
        let data: [ObjectIdentifier: EntityAbstraction] = [
            ObjectIdentifier(TestEntity.self): .concrete
        ]
        let result = sut.createEntityDescription(abstractionData: data, cache: cache)
        XCTAssertEqual(Set(result?.uniquenessConstraints as! [[String]]), [["value", "value2"], ["value3"]])
    }
}
