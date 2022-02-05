//
//  OptionalTests.swift
//  
//
//  Created by ezou on 2022/2/5.
//

import XCTest

@testable import Crush

class OptionalTests: XCTestCase {
    func test_isNil_shouldBeTrue() {
        let sut = Swift.Optional<Int>.none
        XCTAssertTrue(sut.isNil)
    }

    func test_isNil_shouldBeFalse() {
        let sut = Swift.Optional<Int>.some(10)
        XCTAssertFalse(sut.isNil)
    }

    func test_null_shouldBeNil() {
        XCTAssertNil(Swift.Optional<Int>.null)
    }

    func test_contentDescription_shouldBeNull() {
        let sut = Swift.Optional<Int>.none
        XCTAssertEqual(sut.contentDescription, "null")
    }

    func test_contentDescription_shouldDescribeContent() {
        let sut = Swift.Optional<Int>.some(10)
        let result = sut.contentDescription
        XCTAssertEqual("\(10)", result)
    }
}
