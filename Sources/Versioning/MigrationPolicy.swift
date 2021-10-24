//
//  MigrationPolicy.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import Foundation
import CoreData

public class MigrationPolicy {
    public func isStoreCompatible(
        in storage: Storage, with dataModel: DataModel) -> Bool
    {
        guard let url = storage.url else { return true }
        let metadata = try? NSPersistentStoreCoordinator
            .metadataForPersistentStore(
                ofType: storage.storeType, at: url, options: nil)
        guard let metadata = metadata else { return true }
        return dataModel.managedObjectModel.isConfiguration(
            withName: nil, compatibleWithStoreMetadata: metadata)
    }

    public func process(storage: Storage, with dataModel: DataModel) throws {
        guard !isStoreCompatible(in: storage, with: dataModel)
        else { return }
        let result = try resolveIncompatible(dataModel: dataModel, in: storage)
        if result == false {
            throw MigrationError.notMigrated
        }
    }

    public /*abstract*/ func configureStoreDescription(
        _ description: NSPersistentStoreDescription)
    {
        // Implementation
    }

    public /*abstract*/ func resolveIncompatible(
        dataModel: DataModel, in storage: Storage) throws -> Bool
    {
        return false
    }
}

public /*abstract*/ class LightWeightBackupMigrationPolicy: MigrationPolicy {

    public let lightWeightEnabled: Bool

    internal init(lightWeightEnabled: Bool) {
        self.lightWeightEnabled = lightWeightEnabled
    }

    public override func configureStoreDescription(
        _ description: NSPersistentStoreDescription)
    {
        description.shouldInferMappingModelAutomatically = lightWeightEnabled
        description.shouldMigrateStoreAutomatically = lightWeightEnabled
    }

    public override func process(storage: Storage, with dataModel: DataModel) throws {
        do {
            try super.process(storage: storage, with: dataModel)
        } catch {
            if lightWeightEnabled {
                LogHandler.default.log(
                    .error,
                    "Migration of \(Self.self) ends with error: \(error), will try to perform lightweight migration later")
            } else {
                throw error
            }
        }
    }
}

extension MigrationPolicy {
    public static var error: MigrationPolicy {
        ErrorMigrationPolicy()
    }

    public static var lightWeight: MigrationPolicy {
        LightWeightMigrationPolicy()
    }

    public static func adHoc(
        migrations: Set<AdHocMigration>,
        lightWeightBackup flag: Bool = true) -> MigrationPolicy
    {
        AdHocMigrationPolicy(migrations, lightWeightBackup: flag)
    }

    public static func chain(
        _ chain: MigrationChain,
        lightWeightBackup flag: Bool = true) -> MigrationPolicy
    {
        ChainMigrationPolicy(chain, lightWeightBackup: flag)
    }

    public static func adHocChainComposite(
        adHoc: Set<AdHocMigration>,
        chain: MigrationChain,
        lightWeightBackup flag: Bool = true) -> MigrationPolicy
    {
        AdHocChainCompositeMigrationPolicy(
            adHocMigrations: adHoc,
            migrationChain: chain,
            lightWeightBackup: flag)
    }
}

// MARK: Error

public class ErrorMigrationPolicy: LightWeightBackupMigrationPolicy {
    public init() {
        super.init(lightWeightEnabled: false)
    }
}

// MARK: Lightweight

public class LightWeightMigrationPolicy: LightWeightBackupMigrationPolicy {
    public init() {
        super.init(lightWeightEnabled: true)
    }

    public override func resolveIncompatible(
        dataModel: DataModel, in storage: Storage) throws -> Bool
    {
        true
    }
}

// MARK: AdHoc

public class AdHocMigrationPolicy: LightWeightBackupMigrationPolicy {

    public let adHocMigrations: Set<AdHocMigration>

    public init(_ adHocMigrations: Set<AdHocMigration>, lightWeightBackup: Bool) {
        self.adHocMigrations = adHocMigrations
        super.init(lightWeightEnabled: lightWeightBackup)
    }

    public override func resolveIncompatible(
        dataModel: DataModel, in storage: Storage) throws -> Bool
    {
        guard let storage = storage as? ConcreteStorage,
              let sourceName = NSPersistentStoreCoordinator
                .lastActiveVersionName(in: storage) else { return true }
        let migration = adHocMigrations
            .first {
                $0.sourceName == sourceName &&
                $0.migration.name == dataModel.name }
        guard let migration = migration else {
            throw MigrationError.incompatible
        }
        let migrator = AdHocMigrator(
            storage: storage, sourceModelName: sourceName,
            migration: migration.migration, dataModel: dataModel)
        return try migrator.migrate()
    }
}

// MARK: Chain

public class ChainMigrationPolicy: LightWeightBackupMigrationPolicy {

    public let migrationChain: MigrationChain

    public init(_ migrationChain: MigrationChain, lightWeightBackup: Bool) {
        self.migrationChain = migrationChain
        super.init(lightWeightEnabled: lightWeightBackup)
    }

    public override func resolveIncompatible(
        dataModel: DataModel, in storage: Storage) throws -> Bool
    {
        guard let storage = storage as? ConcreteStorage else { return true }
        let migrator = ChainMigrator(
            storage: storage,
            migrationChain: migrationChain,
            dataModel: dataModel)
        return try migrator.migrate()
    }
}

// MARK: AdHoc chain

public class AdHocChainCompositeMigrationPolicy: AdHocMigrationPolicy {
    public let migrationChain: MigrationChain
    private lazy var chainMigrationPolicy =
        ChainMigrationPolicy(migrationChain, lightWeightBackup: lightWeightEnabled)

    public init(
        adHocMigrations: Set<AdHocMigration>,
        migrationChain: MigrationChain,
        lightWeightBackup: Bool)
    {
        self.migrationChain = migrationChain
        super.init(adHocMigrations, lightWeightBackup: lightWeightBackup)
    }

    public override func resolveIncompatible(
        dataModel: DataModel, in storage: Storage) throws -> Bool
    {
        if try super.resolveIncompatible(dataModel: dataModel, in: storage) {
            return true
        }
        return try chainMigrationPolicy.resolveIncompatible(
            dataModel: dataModel, in: storage)
    }
}
