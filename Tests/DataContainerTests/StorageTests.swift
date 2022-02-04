//
//  StorageTests.swift
//  
//
//  Created by ezou on 2021/10/22.
//

import CoreData
import Foundation
import XCTest

@testable import Crush

class StorageTests: XCTestCase {
    func test_description_shouldSetStoreType() {
        let storage = Storage(storeType: NSSQLiteStoreType, url: nil, configuration: nil, options: [])
        let sut = storage.createDescription()
        XCTAssertEqual(sut.type, storage.storeType)
    }

    func test_description_sholdSetURL() {
        let target = URL(string: "crush://test")
        let storage = Storage(storeType: NSSQLiteStoreType, url: target, configuration: nil, options: [])
        let sut = storage.createDescription()
        XCTAssertEqual(sut.url, target)
    }

    func test_description_shouldSetConfiguration() {
        let target = "DEFAULT"
        let storage = Storage(storeType: NSSQLiteStoreType, url: nil, configuration: target, options: [])
        let sut = storage.createDescription()
        XCTAssertEqual(sut.configuration, target)
    }

    func test_descriptionOptions_shouldBeReadOnly() {
        let storage = Storage(storeType: NSSQLiteStoreType, url: nil, configuration: nil, options: [.readOnly])
        let sut = storage.createDescription()
        XCTAssertTrue(sut.isReadOnly)
    }

    func test_descriptionOptions_shouldSetTimeoutInterval() {
        let storage = Storage(storeType: NSSQLiteStoreType, url: nil, configuration: nil, options: [.timeout(10.0)])
        let sut = storage.createDescription()
        XCTAssertEqual(sut.timeout, 10.0)
    }

    func test_descriptionOptions_shouldSetSQLitePragma() {
        let storage = Storage(storeType: NSSQLiteStoreType, url: nil, configuration: nil, options: [SQLiteStorageOption.sqlitePragma(key: "JOURNAL_MODE", value: "DELETE" as NSString)])
        let sut = storage.createDescription()
        XCTAssertEqual(sut.sqlitePragmas["JOURNAL_MODE"], "DELETE" as NSString)
    }

    func test_descriptionOptions_shouldEnablePersistentHistoryTracking() {
        let storage = Storage(storeType: NSSQLiteStoreType, url: nil, configuration: nil, options: [SQLiteStorageOption.persistentHistoryTracking(true)])
        let sut = storage.createDescription()
        XCTAssertEqual(sut.options[NSPersistentHistoryTrackingKey], NSNumber(booleanLiteral: true))
    }

    func test_descriptionOptions_shouldEnablePersistentStoreForceDestroy() {
        let storage = Storage(storeType: NSSQLiteStoreType, url: nil, configuration: nil, options: [SQLiteStorageOption.persistentStoreForceDestory(true)])
        let sut = storage.createDescription()
        XCTAssertEqual(sut.options[NSPersistentStoreForceDestroyOption], NSNumber(booleanLiteral: true))
    }

    func test_descriptionOptions_shouldEnableRemoteChangeNotification() {
        let storage = Storage(storeType: NSSQLiteStoreType, url: nil, configuration: nil, options: [SQLiteStorageOption.remoteChangeNotification(true)])
        let sut = storage.createDescription()
        XCTAssertEqual(sut.options["NSPersistentStoreRemoteChangeNotificationOptionKey"], NSNumber(booleanLiteral: true))
    }

    func test_descriptionOptions_shouldSetSQLiteAnalyze() {
        let storage = Storage(storeType: NSSQLiteStoreType, url: nil, configuration: nil, options: [SQLiteStorageOption.sqliteAnalyze])
        let sut = storage.createDescription()
        XCTAssertEqual(sut.options[NSSQLiteAnalyzeOption], NSNumber(booleanLiteral: true))
    }

    func test_descriptionOptions_shouldSetSQLiteManualVacuum() {
        let storage = Storage(storeType: NSSQLiteStoreType, url: nil, configuration: nil, options: [SQLiteStorageOption.sqliteManualVacuum])
        let sut = storage.createDescription()
        XCTAssertEqual(sut.options[NSSQLiteManualVacuumOption], NSNumber(booleanLiteral: true))
    }

    func test_descriptionOptions_shouldSetCustomOption() {
        let storage = Storage(storeType: NSSQLiteStoreType, url: nil, configuration: nil, options: [.setOption(key: NSPersistentStoreTimeoutOption, value: 10 as NSNumber)])
        let sut = storage.createDescription()
        XCTAssertEqual(sut.options[NSPersistentStoreTimeoutOption], 10 as NSNumber)
    }
#if !os(iOS)
    func test_descriptionOptions_shouldValidateXMLStore() {
        let storage = Storage(storeType: NSSQLiteStoreType, url: nil, configuration: nil, options: [XMLStorageOption.validateXMLStore])
        let sut = storage.createDescription()
        XCTAssertEqual(sut.options[NSValidateXMLStoreOption], NSNumber(booleanLiteral: true))
    }
#endif
#if !os(macOS)
    func test_descriptionOptions_shouldSetPersistentStoreFileProtection() {
        let storage = Storage(storeType: NSSQLiteStoreType, url: nil, configuration: nil, options: [SQLiteStorageOption.persistentStoreFileProtection(type: .completeUnlessOpen)])
        let sut = storage.createDescription()
        XCTAssertEqual(sut.options[NSPersistentStoreFileProtectionKey], FileProtectionType.completeUnlessOpen as NSObject)
    }
#endif
}
