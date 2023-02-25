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
        var anothoerStringProperty = Value.String("anotherStringProperty")

        @Optional
        var uuid = Value.UUID("uuid")

        @Optional
        var object = Relation.ToOne<Entity>("object")

        @Optional
        var anotherObject = Relation.ToOne<Entity>("anotherObject")

        @Optional
        var objects = Relation.ToMany<Entity>("objects")
    }

    class Object: NSObject, EntityEquatableType {
        var predicateValue: NSObject { self }

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
        @objc dynamic var anotherStringProperty: String?
        @objc dynamic var uuid: UUID?

        @objc dynamic var object: Object?
        @objc dynamic var anotherObject: Object?
        @objc dynamic var objects: [Object]?

        init(_ property: Int16?, _ property2: Int16? = nil) {
            self.property = property as NSNumber?
            self.property2 = property2 as NSNumber?
        }

        init(_ string: String?, _ anotherString: String? = nil) {
            self.stringProperty = string
            self.anotherStringProperty = anotherString
        }

        init(_ property: Int16, _ anotherString: String? = nil) {
            self.property = property as NSNumber?
            self.anotherStringProperty = anotherString
        }

        init(_ string: String, _ property2: Int16) {
            self.property2 = property2 as NSNumber?
            self.stringProperty = string
        }

        init(_ object: Object, _ anotherObject: Object? = nil) {
            self.object = object
            self.anotherObject = anotherObject
        }

        init(_ object: Object, _ objects: [Object]) {
            self.object = object
            self.objects = objects
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
        XCTAssertEqual(objects.filtered(using: sut).count, 1)
    }
    
    func test_equalToNil_shouldContainAllNils() {
        let sut = \Entity.object == nil
        let object = Object(1)
        let objects = NSArray(array: [
            Object(object), Object(2), Object(3)
        ])
        XCTAssertEqual(objects.filtered(using: sut).count, 2)
    }

    func test_equalToValue_shouldReturnTrue() {
        let object = Object(1)
        let sut = \Entity.object == object
        let objects = NSArray(array: [
            Object(object), Object(2), Object(3)
        ])
        XCTAssertEqual(objects.filtered(using: sut).count, 1)
    }

    func test_notEqualToValue_shouldReturnTrue() {
        let object = Object(1)
        let sut = \Entity.object != object
        let objects = NSArray(array: [
            Object(object), Object(2), Object(3)
        ])
        XCTAssertEqual(objects.filtered(using: sut).count, 2)
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
            Object(Swift.Optional<Int16>.none), Object(2), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(Swift.Optional<Int16>.none)])
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
            Object(Swift.Optional<Int16>.none), Object(2), Object(3)
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

    func test_smallerOperator_shouldReturnObjectsWithPropertyLessThan3() {
        let sut = \Entity.property < 3
        let target = NSArray(array: [
            Object(1), Object(2), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(1), Object(2)])
    }

    func test_smallerOperator_shouldReturnObjectsWhichPropertyLessThanProperty2() {
        let sut = \Entity.property < \Entity.property2
        let target = NSArray(array: [
            Object(1, 2), Object(2, 3), Object(3, 2)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(1, 2), Object(2, 3)])
    }

    func test_LessThanOrEqualToOperator_shouldReturnObjectsWithPropertyLessThanOrEqualTo2() {
        let sut = \Entity.property <= 2
        let target = NSArray(array: [
            Object(1), Object(2), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(1), Object(2)])
    }

    func test_LessThanOrEqualToOperator_shouldReturnObjectsWhichPropertyLessThanOrEqualToProperty2() {
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

    func test_betweenOperator_shouldReturnObjectsWithPropertyBetween1to2() {
        let sut = \Entity.property <> (1..<3)
        let target = NSArray(array: [
            Object(1), Object(2), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(1), Object(2)])
    }

    func test_beginsWithOperator_shouldReturnStringBeginsWithA() {
        let sut = \Entity.stringProperty |~ "A"
        let target = NSArray(array: [
            Object("ABC"), Object("ACD"), Object("asd")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("ABC"), Object("ACD")])
    }

    func test_beginsWithOperator_shouldReturnEntityWithStringPropertyBeginingWithAnotherStringProperty() {
        let sut = \Entity.stringProperty |~ \Entity.anothoerStringProperty
        let target = NSArray(array: [
            Object("ABC", "AB"), Object("ACD", "D"), Object("asd", "A")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("ABC", "AB")])
    }

    func test_beginsWithOperator_shouldReturnEntityWithStringPropertyBeginingWithAnotherStringifyProperty() {
        let sut = \Entity.stringProperty |~ \Entity.property2
        let target = NSArray(array: [
            Object("13", 1), Object("ACD", "D"), Object("asd", "A")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("13", 1)])
    }

    func test_endsWithOperator_shouldReturnStringEndsWithA() {
        let sut = \Entity.stringProperty ~| "A"
        let target = NSArray(array: [
            Object("CBA"), Object("CDA"), Object("asd")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("CBA"), Object("CDA")])
    }

    func test_endsWithOperator_shouldReturnEntityWithStringPropertyEndingWithAnotherStringProperty() {
        let sut = \Entity.stringProperty ~| \Entity.anothoerStringProperty
        let target = NSArray(array: [
            Object("ABC", "AB"), Object("ACD", "D"), Object("asd", "A")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("ACD", "D")])
    }

    func test_endsWithOperator_shouldReturnEntityWithStringPropertyEndingWithAnotherStringifyProperty() {
        let sut = \Entity.stringProperty ~| \Entity.property2
        let target = NSArray(array: [
            Object("123", 3), Object("ACD", "D"), Object("asd", "A")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("123", 3)])
    }

    func test_containsOperator_shouldReturnStringContainsA() {
        let sut = \Entity.stringProperty <> "A"
        let target = NSArray(array: [
            Object("CBA"), Object("CDA"), Object("asd")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("CBA"), Object("CDA")])
    }

    func test_containsOperator_shouldReturnEntityWithStringPropertyContainingAnotherStringProperty() {
        let sut = \Entity.stringProperty <> \Entity.anothoerStringProperty
        let target = NSArray(array: [
            Object("ABC", "AB"), Object("ACD", "D"), Object("asd", "A")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("ABC", "AB"), Object("ACD", "D")])
    }

    func test_containsOperator_shouldReturnEntityWithStringPropertyContainingAnotherStringifyProperty() {
        let sut = \Entity.stringProperty <> \Entity.property2
        let target = NSArray(array: [
            Object("123", 2), Object("ACD", "D"), Object("asd", "A")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("123", 2)])
    }

    func test_likeOperator_shouldReturnStringLikeC_A() {
        let sut = \Entity.stringProperty |~| "C*A"
        let target = NSArray(array: [
            Object("CBA"), Object("CDA"), Object("asd")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("CBA"), Object("CDA")])
    }

    func test_likeOperator_shouldReturnEntityWithStringPropertyLikeAnotherStringProperty() {
        let sut = \Entity.stringProperty |~| \Entity.anothoerStringProperty
        let target = NSArray(array: [
            Object("ABC", "A*B"), Object("ACD", "A*D"), Object("asd", "A")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("ACD", "A*D")])
    }

    func test_likeOperator_shouldReturnEntityWithStringPropertyLikeAnotherStringifyProperty() {
        let sut = \Entity.stringProperty |~| \Entity.property2
        let target = NSArray(array: [
            Object("123", 123), Object("ACD", "A*D"), Object("asd", "A")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("123", 123)])
    }

    func test_matchOperator_shouldReturnStringContainsAOra() {
        let sut = \Entity.stringProperty |*| "[A-Z]+"
        let target = NSArray(array: [
            Object("CBA"), Object("CDA"), Object("asd")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("CBA"), Object("CDA")])
    }

    func test_matchOperator_shouldReturnEntityWithStringPropertyMatchingAnotherStringProperty() {
        let sut = \Entity.stringProperty |*| \Entity.anothoerStringProperty
        let target = NSArray(array: [
            Object("AA", "[A]+"), Object("ACD", "[E]+"), Object("aaa", "[Aa]+")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("AA", "[A]+"), Object("aaa", "[Aa]+")])
    }

    func test_matchOperator_shouldReturnEntityWithStringPropertyMatchingAnotherStringifyProperty() {
        let sut = \Entity.stringProperty |*| \Entity.property2
        let target = NSArray(array: [
            Object("123", 123), Object("ACD", "[E]+"), Object("aaa", "[Aa]+")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object("123", 123)])
    }

    func test_beginsWithOperator_shouldReturnStringifyPropertyBeginsWith1() {
        let sut = \Entity.property |~ "1"
        let target = NSArray(array: [
            Object(123), Object(1), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(123), Object(1)])
    }

    func test_beginsWithOperator_shouldReturnEntityWithStringifyPropertyBeginingWithAnotherStringProperty() {
        let sut = \Entity.property |~ \Entity.anothoerStringProperty
        let target = NSArray(array: [
            Object(123, "1"), Object(123, "23")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(123, "1")])
    }

    func test_beginsWithOperator_shouldReturnEntityWithStringifyPropertyBeginingWithAnotherStringifyProperty() {
        let sut = \Entity.property |~ \Entity.property2
        let target = NSArray(array: [
            Object(123, 12), Object(123, 2)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(123, 12)])
    }

    func test_endsWithOperator_shouldReturnStringifyPropertyEndsWith1() {
        let sut = \Entity.property ~| "1"
        let target = NSArray(array: [
            Object(321), Object(1), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(321), Object(1)])
    }

    func test_endsWithOperator_shouldReturnEntityWithStringifyPropertyEndingWithAnotherStringProperty() {
        let sut = \Entity.property ~| \Entity.anothoerStringProperty
        let target = NSArray(array: [
            Object(123, "2"), Object(123, "23")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(123, "23")])
    }

    func test_endsWithOperator_shouldReturnEntityWithStringifyPropertyEndingWithAnotherStringifyProperty() {
        let sut = \Entity.property ~| \Entity.property2
        let target = NSArray(array: [
            Object(123, 123), Object(123, 2)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(123, 123)])
    }

    func test_containsOperator_shouldReturnStringifyPropertyContaining2() {
        let sut = \Entity.property <> "2"
        let target = NSArray(array: [
            Object(321), Object(1), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(321)])
    }

    func test_containsOperator_shouldReturnEntityWithStringifyPropertyContainingAnotherStringProperty() {
        let sut = \Entity.property <> \Entity.anothoerStringProperty
        let target = NSArray(array: [
            Object(123, "2"), Object(123, "456")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(123, "2")])
    }

    func test_containsOperator_shouldReturnEntityWithStringifyPropertyContainingAnotherStringifyProperty() {
        let sut = \Entity.property <> \Entity.property2
        let target = NSArray(array: [
            Object(123, 123), Object(123, 2)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(123, 123), Object(123, 2)])
    }

    func test_likeOperator_shouldReturnStringifyPropertyLike1_3() {
        let sut = \Entity.property |~| "1*3"
        let target = NSArray(array: [
            Object(123), Object(113), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(123), Object(113)])
    }

    func test_likeOperator_shouldReturnEntityWithStringifyPropertyLikeAnotherStringProperty() {
        let sut = \Entity.property |~| \Entity.anothoerStringProperty
        let target = NSArray(array: [
            Object(123, "1*3"), Object(123, "456")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(123, "[0-9]+")])
    }

    func test_likeOperator_shouldReturnEntityWithStringifyPropertyLikeAnotherStringifyProperty() {
        let sut = \Entity.property |~| \Entity.property2
        let target = NSArray(array: [
            Object(123, 123), Object(123, 2)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(123, 123)])
    }

    func test_matchOperator_shouldReturnStringifyPropertyMatchSingleDigitNumber() {
        let sut = \Entity.property |*| "[0-9]"
        let target = NSArray(array: [
            Object(123), Object(1), Object(3)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(1), Object(3)])
    }

    func test_matchOperator_shouldReturnEntityWithStringifyPropertyMatchingAnotherStringProperty() {
        let sut = \Entity.property |*| \Entity.anothoerStringProperty
        let target = NSArray(array: [
            Object(123, "[0-9]+"), Object(123, "[E]+")
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(123, "[0-9]+")])
    }

    func test_matchOperator_shouldReturnEntityWithStringifyPropertyMatchingAnotherStringifyProperty() {
        let sut = \Entity.property |*| \Entity.property2
        let target = NSArray(array: [
            Object(123, 123), Object(123, 2)
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(123, 123)])
    }

    func test_notEqualObject_shouldReturnValuesObjectNotEqualToAnotherObject() {
        let sut = \Entity.object != \.anotherObject
        let another = Object(1)
        let target = NSArray(array: [
            Object(another, nil), another
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(another, nil)])
    }

    func test_equalObject_shouldReturnValuesObjectEqualToAnotherObject() {
        let sut = \Entity.object == \.anotherObject
        let another = Object(1)
        let target = NSArray(array: [
            Object(another, another), Object(another, nil), another
        ])
        let result = target.filtered(using: sut) as! [Object]
        XCTAssertEqual(result, [Object(another, another), another])
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
