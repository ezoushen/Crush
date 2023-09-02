//
//  LazyMapSetTests.swift
//  
//
//  Created by EZOU on 2023/9/1.
//

import XCTest

@testable import Crush

class LazyMapSetTests: XCTestCase {
    func test_count_shouldEqualToUnderlyingSet() {
        let nsset = NSSet(array: [0])
        let sut = LazyMapSet<Int, String>.from(nsset) {
            "\($0)"
        } to: {
            Int($0)!
        }
        XCTAssertEqual(nsset.count, sut.count)
    }
    
    func test_objectEnumerator_shouldIterateAllMappedObjects() {
        let nsset = NSSet(array: [0])
        let sut = LazyMapSet<Int, String>.from(nsset) {
            "\($0)"
        } to: {
            Int($0)!
        }
        let array = sut.objectEnumerator().allObjects as? [String]
        XCTAssertEqual(["0"], array)
    }
    
    func test_member_shouldReturnTheObject() {
        let nsset = NSSet(array: [0])
        let sut = LazyMapSet<Int, String>.from(nsset) {
            "\($0)"
        } to: {
            Int($0)!
        }
        XCTAssertEqual(sut.member("0") as? String, "0")
    }
}
