//
//  LazyMapMutableSetTests.swift
//
//
//  Created by EZOU on 2023/9/1.
//

import XCTest

@testable import Crush

class LazyMapMutableSetTests: XCTestCase {
    
    func test_add_shouldMapAddedObject() {
        let mutableSet = NSMutableSet()
        let sut = LazyMapMutableSet<Int, String>.from(mutableSet) {
            "\($0)"
        } to: {
            Int($0)!
        }
        sut.add("0")
        XCTAssertTrue(mutableSet.contains(0))
    }
    
    func test_remove_shouldMapRemovedObject() {
        let mutableSet = NSMutableSet(array: [0])
        let sut = LazyMapMutableSet<Int, String>.from(mutableSet) {
            "\($0)"
        } to: {
            Int($0)!
        }
        sut.remove("0")
        XCTAssertEqual(mutableSet.count, 0)
    }
    
    func test_count_shouldEqualToUnderlyingSet() {
        let mutableSet = NSMutableSet(array: [0])
        let sut = LazyMapMutableSet<Int, String>.from(mutableSet) {
            "\($0)"
        } to: {
            Int($0)!
        }
        XCTAssertEqual(mutableSet.count, sut.count)
    }
    
    func test_objectEnumerator_shouldIterateAllMappedObjects() {
        let mutableSet = NSMutableSet(array: [0])
        let sut = LazyMapMutableSet<Int, String>.from(mutableSet) {
            "\($0)"
        } to: {
            Int($0)!
        }
        let array = sut.objectEnumerator().allObjects as? [String]
        XCTAssertEqual(["0"], array)
    }
    
    func test_mutableCopy_oldInstanceShouldRemainUnchanged() {
        let mutableSet = NSMutableSet(array: [0])
        let sut = LazyMapMutableSet<Int, String>.from(mutableSet) {
            "\($0)"
        } to: {
            Int($0)!
        }
        let result = sut.mutableCopy() as! NSMutableSet
        result.add("1")
        XCTAssertFalse(sut.contains("1"))
    }
}
