//
//  OperatorsTests.swift
//  
//
//  Created by ezou on 2022/2/5.
//

import XCTest

@testable import Crush

class OperatorsTests: XCTestCase {

    class Entity: Crush.Entity {
        @Optional
        var property = Value.Int16("property")

        @Optional
        var property2 = Value.Int16("property2")

        @Optional
        var stringProperty = Value.String("stringProperty")

        @Optional
        var uuid = Value.UUID("uuid")

        @Optional
        var object = Relation.ToOne<Entity>("object")

        @Optional
        var objects = Relation.ToMany<Entity>("objects")
    }

    class Object: NSObject {
        override func isEqual(_ object: Any?) -> Bool {
            let objectsEqual = self.objects == (object as? Object)?.objects
            return property == (object as? Object)?.property &&
            property2 == (object as? Object)?.property2 &&
            stringProperty == (object as? Object)?.stringProperty &&
            uuid == (object as? Object)?.uuid &&
            self.object == (object as? Object)?.object &&
            objectsEqual
        }

        @objc dynamic var property: NSNumber?
        @objc dynamic var property2: NSNumber?
        @objc dynamic var stringProperty: String?
        @objc dynamic var uuid: UUID?

        @objc dynamic var object: Object?
        @objc dynamic var objects: [Object]?

        init(_ property: Int16?, _ property2: Int16? = nil) {
            self.property = property as NSNumber?
            self.property2 = property2 as NSNumber?
        }

        init(_ string: String?) {
            self.stringProperty = string
        }

        init(_ object: Object) {
            self.object = object
        }

        init(_ objects: [Object]) {
            self.objects = objects
        }
        
        init(_ uuid: UUID) {
            self.uuid = uuid
        }
    }

    func test_staticTruePredicate_shouldEqualToTruePredicate() {
        XCTAssertEqual(NSPredicate.true, NSPredicate(value: true))
    }

    func test_staticFalsePredicate_shouldEqualToFalsePredicate() {
        XCTAssertEqual(NSPredicate.false, NSPredicate(value: false))
    }
    
    func test_notEqualToNil_shouldFilterOutNils() {
        let sut = \Entity.object != nil
        let object = Object(1)
        let objects = NSArray(array: [
            Object(object), Object(2), Object(3)
        ])
        
        XCTAssertTrue(objects.filtered(using: sut).count == 1)
    }
    
    func test_equalToNil_shouldContainAllNils() {
        let sut = \Entity.object == nil
        let object = Object(1)
        let objects = NSArray(array: [
            Object(object), Object(2), Object(3)
        ])
        
        XCTAssertTrue(objects.filtered(using: sut).count == 2)
    }

    func test_equalToValue_shouldReturnTrue() {
//        let object = Object(1)
//        let sut = \Entity.object == object
//        let objects = NSArray(array: [
//            Object(object), Object(2), Object(3)
//        ])
//
//        XCTAssertTrue(objects.filtered(using: sut).count == 2)
    }

    func test_notOperator_shouldPrependNOT() {
        XCTAssertEqual(!NSPredicate.true, NSCompoundPredicate(notPredicateWithSubpredicate: .true))
    }

    func test_orOperator_shouldEqualToOrCompoundPredicate() {
        XCTAssertEqual(
            NSPredicate.true || NSPredicate.true,
            NSCompoundPredicate(orPredicateWithSubpredicates: [.true, .true]))
    }

    func test_andOperator_shouldEqualToAndCompoundPredicate() {
        XCTAssertEqual(
            NSPredicate.true && NSPredicate.true,
            NSCompoundPredicate(andPredicateWithSubpredicates: [.true, .true]))
    }

    func test_inOperator_shouldInSet() {
        let set: Set<Int16> = [1, 2]
        let sut = \Entity.property <> `set`
        let array = NSArray(array: [
            Object(1), Object(2), Object(3)
        ])
        let result = array.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(1), Object(2)])
    }

    func test_inOperator_shouldInArray() {
        let array: Array<Int16> = [1, 2]
        let sut = \Entity.property <> array
        let target = NSArray(array: [
            Object(1), Object(2), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(1), Object(2)])
    }

    func test_equalOperator_shouldReturnSpecificObject() {
        let sut = \Entity.property == 1
        let target = NSArray(array: [
            Object(1), Object(2), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(1)])
    }

    func test_equalOperator_shouldReturnNilObject() {
        let sut = \Entity.property == nil
        let target = NSArray(array: [
            Object(nil), Object(2), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(nil)])
    }

    func test_notEqualOperator_shouldReturnOtherObjects() {
        let sut = \Entity.property != 1
        let target = NSArray(array: [
            Object(1), Object(2), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(2), Object(3)])
    }

    func test_notEqualOperator_shouldReturnNonNilObjects() {
        let sut = \Entity.property != nil
        let target = NSArray(array: [
            Object(nil), Object(2), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(2), Object(3)])
    }

    func test_equalOperator_shouldReturnObjectsWithTwoSameProperties() {
        let sut: TypedPredicate<Entity> = \Entity.property == \Entity.property2
        let target = NSArray(array: [
            Object(1, 1), Object(2, 2), Object(3, 2)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(1, 1), Object(2, 2)])
    }

    func test_equalOperator_shouldReturnObjectsWithTwoDifferentProperties() {
        let sut = \Entity.property != \Entity.property2
        let target = NSArray(array: [
            Object(1, 2), Object(2, 3), Object(3, 3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(1, 2), Object(2, 3)])
    }

    func test_greaterOperator_shouldReturnObjectsWithPropertyGreaterThan1() {
        let sut = \Entity.property > 1
        let target = NSArray(array: [
            Object(1), Object(2), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(2), Object(3)])
    }

    func test_greaterOperator_shouldReturnObjectsWhichPropertyGreaterThanProperty2() {
        let sut = \Entity.property > \Entity.property2
        let target = NSArray(array: [
            Object(1, 2), Object(2, 1), Object(3, 2)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(2, 1), Object(3, 2)])
    }

    func test_greaterThanOrEqualToOperator_shouldReturnObjectsWithPropertyGreaterThanOrEqualTo2() {
        let sut = \Entity.property >= 2
        let target = NSArray(array: [
            Object(1), Object(2), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(2), Object(3)])
    }

    func test_greaterThanOrEqualToOperator_shouldReturnObjectsWhichPropertyGreaterThanOrEquaToProperty2() {
        let sut = \Entity.property >= \Entity.property2
        let target = NSArray(array: [
            Object(1, 2), Object(2, 2), Object(3, 2)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(2, 2), Object(3, 2)])
    }

    func test_smallerOperator_shouldReturnObjectsWithPropertySmallerThan3() {
        let sut = \Entity.property < 3
        let target = NSArray(array: [
            Object(1), Object(2), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(1), Object(2)])
    }

    func test_smallerOperator_shouldReturnObjectsWhichPropertySmallerThanProperty2() {
        let sut = \Entity.property < \Entity.property2
        let target = NSArray(array: [
            Object(1, 2), Object(2, 3), Object(3, 2)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(1, 2), Object(2, 3)])
    }

    func test_smallerThanOrEqualToOperator_shouldReturnObjectsWithPropertySmallerThanOrEqualTo2() {
        let sut = \Entity.property <= 2
        let target = NSArray(array: [
            Object(1), Object(2), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(1), Object(2)])
    }

    func test_smallerThanOrEqualToOperator_shouldReturnObjectsWhichPropertySmallerThanOrEqualToProperty2() {
        let sut = \Entity.property <= \Entity.property2
        let target = NSArray(array: [
            Object(1, 2), Object(2, 2), Object(3, 1)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(1, 2), Object(2, 2)])
    }

    func test_betweenOperator_shouldReturnObjectsWithPropertyBetween2to4() {
        let sut = \Entity.property <> (2...4)
        let target = NSArray(array: [
            Object(1), Object(2), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(2), Object(3)])
    }

    func test_beginsWithOperator_shouldReturnStringBeginsWithA() {
        let sut = \Entity.stringProperty |~ "A"
        let target = NSArray(array: [
            Object("ABC"), Object("ACD"), Object("asd")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("ABC"), Object("ACD")])
    }

    func test_endsWithOperator_shouldReturnStringEndsWithA() {
        let sut = \Entity.stringProperty ~| "A"
        let target = NSArray(array: [
            Object("CBA"), Object("CDA"), Object("asd")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("CBA"), Object("CDA")])
    }

    func test_containsOperator_shouldReturnStringContainsA() {
        let sut = \Entity.stringProperty <> "A"
        let target = NSArray(array: [
            Object("CBA"), Object("CDA"), Object("asd")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("CBA"), Object("CDA")])
    }

    func test_likeOperator_shouldReturnStringLikeC_A() {
        let sut = \Entity.stringProperty |~| "C*A"
        let target = NSArray(array: [
            Object("CBA"), Object("CDA"), Object("asd")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("CBA"), Object("CDA")])
    }

    func test_matchOperator_shouldReturnStringContainsAOra() {
        let sut = \Entity.stringProperty |*| "[A-Z]+"
        let target = NSArray(array: [
            Object("CBA"), Object("CDA"), Object("asd")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("CBA"), Object("CDA")])
    }

    func test_beginsWithOperator_shouldReturnStringifyPropertyBeginsWith1() {
        let sut = \Entity.property |~ "1"
        let target = NSArray(array: [
            Object(123), Object(1), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(123), Object(1)])
    }

    func test_endsWithOperator_shouldReturnStringifyPropertyEndsWith1() {
        let sut = \Entity.property ~| "1"
        let target = NSArray(array: [
            Object(321), Object(1), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(321), Object(1)])
    }

    func test_containsOperator_shouldReturnStringifyPropertyContainsWith2() {
        let sut = \Entity.property <> "2"
        let target = NSArray(array: [
            Object(321), Object(1), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(321)])
    }

    func test_likeOperator_shouldReturnStringifyPropertyLike1_3() {
        let sut = \Entity.property |~| "1*3"
        let target = NSArray(array: [
            Object(123), Object(113), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(123), Object(113)])
    }

    func test_matchOperator_shouldReturnStringifyPropertyMatchSingleDigitNumber() {
        let sut = \Entity.property |*| "[0-9]"
        let target = NSArray(array: [
            Object(123), Object(1), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(1), Object(3)])
    }

    func test_subquery_shouldReturnObjectsWhichObjectPropertyEqualTo1() {
        let sut = TypedPredicate<Entity>.join(\.object, predicate: \Entity.property == 1)
        let target = NSArray(array: [
            Object(Object(1)), Object(Object(0)), Object(Object(3))
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(Object(1))])
    }

    func test_subquery_shouldReturnObjectsWhichAmountOfObjectsWithPropertyGreaterThan1GreaterThan2() {
        let sut = TypedPredicate<Entity>.subquery(\.objects, predicate: \Entity.property > 1, collectionQuery: .count(greaterThan: 2))
        let target = NSArray(array: [
            Object([Object(1), Object(2), Object(3)]),
            Object([Object(4), Object(1), Object(3)]),
            Object([Object(4), Object(5), Object(3)]),
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object([Object(4), Object(5), Object(3)])])
    }

    func test_subqueryUUID_shouldNotThrowingException() {
        let uuids = [UUID(), UUID(), UUID()]
        let sut = TypedPredicate<Entity>.join(
            \.object, predicate: \Entity.uuid == uuids[0] && \.property == nil)
        let target = NSArray(array: [
            Object(Object(UUID())), Object(Object(UUID())), Object(Object(uuids[0]))
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(Object(uuids[0]))])
    }
}
