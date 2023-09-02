//
//  LazyMapMutableOrderedSetTests.swift
//  
//
//  Created by EZOU on 2023/9/1.
//

import XCTest

@testable import Crush

class LazyMapOrderedSetTests: XCTestCase {
    func test_objectAt_shouldReturnMappedObject() {
        let orderedSet = NSOrderedSet(array: [1, 2, 3])
        let sut = LazyMapOrderedSet<Int, String>.from(orderedSet) {
            "\($0)"
        } to: {
            Int($0)!
        }
        XCTAssertEqual(sut.object(at: 1) as! String, "2")
    }
    
    func test_isEqual_shouldCompareUnderlyingSet() {
        let orderedSet = NSOrderedSet(array: [1, 2, 3])
        let sut = LazyMapOrderedSet<Int, String>.from(orderedSet) {
            "\($0)"
        } to: {
            Int($0)!
        }
        XCTAssertTrue(sut.isEqual(NSOrderedSet(array: ["1", "2", "3"])))
    }
}
