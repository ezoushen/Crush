//
//  SearchStringTests.swift
//  
//
//  Created by EZOU on 2022/2/5.
//

import XCTest
import Crush

class SearchStringTests: XCTestCase {
    func test_caseInsensitive_shouldReturnTrue() {
        let sut = PropertyCondition.string(beginsWith: .caseInsensitive("a"))
        XCTAssertTrue(sut.evaluate(with: "ABC"))
    }

    func test_diacriticInsensitive_shouldReturnTrue() {
        let sut = PropertyCondition.string(beginsWith: .diacriticInsensitive("a"))
        XCTAssertTrue(sut.evaluate(with: "à"))
    }

    func test_caseDiacriticInsensitive_shouldReturnTrue() {
        let sut = PropertyCondition.string(beginsWith: .caseDiacriticInsensitive("A"))
        XCTAssertTrue(sut.evaluate(with: "à"))
    }

    func test_initializer_shouldEqualToString() {
        let sut: SearchString = "abc"
        XCTAssertEqual(sut, "abc")
    }

    func test_keyPath_shouldParsePropertyName() {
        class TestEntity: Entity {
            @Optional
            var property = Value.String("property")
        }
        let string = SearchString(\TestEntity.property)
        XCTAssertEqual(string.string, "property")
        XCTAssertEqual(string.type, .plain)
    }

    func test_keyPathCaseInsensitive_shouldParsePropertyName() {
        class TestEntity: Entity {
            @Optional
            var property = Value.String("property")
        }
        let string = SearchString.caseInsensitive(\TestEntity.property)
        XCTAssertEqual(string.string, "property")
        XCTAssertEqual(string.type, .caseInsensitive)
    }

    func test_keyPathCaseDiacriticInsensitive_shouldParsePropertyName() {
        class TestEntity: Entity {
            @Optional
            var property = Value.String("property")
        }
        let string = SearchString.caseDiacriticInsensitive(\TestEntity.property)
        XCTAssertEqual(string.string, "property")
        XCTAssertEqual(string.type, .caseDiacriticInsensitive)
    }

    func test_keyPathDiacriticInsensitive_shouldParsePropertyName() {
        class TestEntity: Entity {
            @Optional
            var property = Value.String("property")
        }
        let string = SearchString.diacriticInsensitive(\TestEntity.property)
        XCTAssertEqual(string.string, "property")
        XCTAssertEqual(string.type, .diacriticInsensitive)
    }

    func test_keyPathStringifyCaseInsensitive_shouldParsePropertyName() {
        class TestEntity: Entity {
            @Optional
            var property = Value.Int16("property")
        }
        let string = SearchString.caseInsensitive(\TestEntity.property)
        XCTAssertEqual(string.string, "property")
        XCTAssertEqual(string.type, .caseInsensitive)
    }

    func test_keyPathStringifyCaseDiacriticInsensitive_shouldParsePropertyName() {
        class TestEntity: Entity {
            @Optional
            var property = Value.Int16("property")
        }
        let string = SearchString.caseDiacriticInsensitive(\TestEntity.property)
        XCTAssertEqual(string.string, "property")
        XCTAssertEqual(string.type, .caseDiacriticInsensitive)
    }

    func test_keyPathStringifyDiacriticInsensitive_shouldParsePropertyName() {
        class TestEntity: Entity {
            @Optional
            var property = Value.Int16("property")
        }
        let string = SearchString.diacriticInsensitive(\TestEntity.property)
        XCTAssertEqual(string.string, "property")
        XCTAssertEqual(string.type, .diacriticInsensitive)
    }
}
