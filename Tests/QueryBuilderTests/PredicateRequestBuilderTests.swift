//
//  PredicateRequestBuilderTests.swift
//  
//
//  Created by EZOU on 2022/7/13.
//

import Foundation
import XCTest
import CoreData

@testable import Crush

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
class PredicateRequestBuilderTests: XCTestCase {
    struct DummyConfig: RequestConfig {
        var predicate: NSPredicate?
        func createStoreRequest() -> NSPersistentStoreRequest {
            let request = NSPersistentStoreRequest()
            return request
        }
    }
    
    class TestEntity: Entity {
        @Optional
        var integerValue = Value.Int16("integerValue")
    }
    
    var sut: PredicateRequestBuilder<TestEntity>!
    
    override func setUp() async throws {
        sut = .init(config: DummyConfig())
    }
    
    func test_request_where_shouldUpdatePredicate() {
        let predicate = sut
            .where(\TestEntity.integerValue == 0)
            .requestConfig
            .predicate
        XCTAssertEqual(\TestEntity.integerValue == 0, predicate)
    }
    
    func test_request_andWhere_shouldComposePredicate() {
        let preicate = sut
            .where(.true)
            .andWhere(\TestEntity.integerValue == 0)
            .requestConfig
            .predicate
        XCTAssertEqual(.true && \TestEntity.integerValue == 0, preicate)
    }
    
    func test_request_orWhere_shouldComposePredicate() {
        let predicate = sut
            .where(.true)
            .orWhere(\.integerValue == 0)
            .requestConfig
            .predicate
        XCTAssertEqual(.true || \TestEntity.integerValue == 0, predicate)
    }
    
    func test_request_where_shouldConstructPredicate() {
        let predicate = sut
            .where("integerValue = %d", 0)
            .requestConfig
            .predicate
        XCTAssertEqual(\TestEntity.integerValue == 0, predicate)
    }
    
    func test_request_andWhere_shouldConstructPredicate() {
        let predicate = sut
            .where(.true)
            .andWhere("integerValue = %d", 0)
            .requestConfig
            .predicate
        XCTAssertEqual(.true && \TestEntity.integerValue == 0, predicate)
    }
    
    func test_request_orWhere_shouldConstructPredicate() {
        let predicate = sut
            .where(.true)
            .orWhere("integerValue = %d", 0)
            .requestConfig
            .predicate
        XCTAssertEqual(.true || \TestEntity.integerValue == 0, predicate)
    }
}
