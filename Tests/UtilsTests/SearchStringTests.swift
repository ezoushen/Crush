//
//  SearchStringTests.swift
//  
//
//  Created by 沈昱佐 on 2022/2/5.
//

import XCTest
import Crush

class SearchStringTests: XCTestCase {
    func test_caseInsensitive_shouldReturnTrue() {
        let sut = PropertyCondition(beginsWith: .caseInsensitive("a"))
        XCTAssertTrue(sut.evaluate(with: "ABC"))
    }

    func test_diacriticInsensitive_shouldReturnTrue() {
        let sut = PropertyCondition(beginsWith: .diacriticInsensitive("a"))
        XCTAssertTrue(sut.evaluate(with: "à"))
    }

    func test_caseDiacriticInsensitive_shouldReturnTrue() {
        let sut = PropertyCondition(beginsWith: .caseDiacriticInsensitive("A"))
        XCTAssertTrue(sut.evaluate(with: "à"))
    }

    func test_initializer_shouldEqualToString() {
        let sut = SearchString("abc")
        XCTAssertEqual(sut, "abc")
    }
}
