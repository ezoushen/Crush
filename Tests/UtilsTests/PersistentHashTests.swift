//
//  PersistentHashTests.swift
//  
//
//  Created by ezou on 2022/2/5.
//

import Foundation
import XCTest

@testable import Crush

public class PersistentHashTests: XCTestCase {
    func test_hashOrderedNumbers_shouldBeEqual() {
        let value = PersistentHash.ordered(10, 11)
        let sut = PersistentHash.ordered(10, 11)
        XCTAssertEqual(value, sut)
    }

    func test_hashReverseOrderedNumbers_shouldNotBeEqual() {
        let value = PersistentHash.ordered(10, 11)
        let sut = PersistentHash.ordered(11, 10)
        XCTAssertNotEqual(value, sut)
    }

    func test_hashUnorderedNumbers_shouldBeEqual() {
        let value = PersistentHash.unordered(10, 11)
        let sut = PersistentHash.unordered(10, 11)
        XCTAssertEqual(value, sut)
    }

    func test_hashReversedUnorderedNumbers_shouldBeEqual() {
        let value = PersistentHash.unordered(10, 11)
        let sut = PersistentHash.unordered(11, 10)
        XCTAssertEqual(value, sut)
    }

    func test_hashFromString_shouldBeEqual() {
        let value = PersistentHash.fromString("STRING")
        let sut = PersistentHash.fromString("STRING")
        XCTAssertEqual(value, sut)
    }

    func test_hashFromString_shouldNotBeEqual() {
        let value = PersistentHash.fromString("STRING")
        let sut = PersistentHash.fromString("ANOTHER STRING")
        XCTAssertNotEqual(value, sut)
    }
}

