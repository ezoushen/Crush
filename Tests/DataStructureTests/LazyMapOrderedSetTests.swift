//
//  LazyMapOrderedSetTests.swift
//  
//
//  Created by EZOU on 2023/9/1.
//

import XCTest

@testable import Crush

class LazyMapMutableOrderedSetTests: XCTestCase {
    func test_insert_shouldInsertMappedObject() {
        let orderedSet = NSMutableOrderedSet(array: [1, 2, 3])
        let sut = LazyMapMutableOrderedSet<Int, String>.from(orderedSet) {
            "\($0)"
        } to: {
            Int($0)!
        }
        sut.insert("0", at: 0)
        XCTAssertEqual(["0", "1", "2", "3"], sut.array as! [String])
    }
    
    func test_remove_shouldRemoveMappedObjectAtIndexSet() {
        let orderedSet = NSMutableOrderedSet(array: [1, 2, 3])
        let sut = LazyMapMutableOrderedSet<Int, String>.from(orderedSet) {
            "\($0)"
        } to: {
            Int($0)!
        }
        sut.removeObjects(at: [0, 1])
        XCTAssertEqual(["3"], sut.array as! [String])
    }
    
    func test_isEqual_shouldCompareUnderlyingSet() {
        let orderedSet = NSMutableOrderedSet(array: [1, 2, 3])
        let sut = LazyMapMutableOrderedSet<Int, String>.from(orderedSet) {
            "\($0)"
        } to: {
            Int($0)!
        }
        XCTAssertTrue(sut.isEqual(NSOrderedSet(array: ["1", "2", "3"])))
    }
}
