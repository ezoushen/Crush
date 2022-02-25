//
//  MigrationPolicy.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import Foundation
import CoreData

public class MigrationPolicy {
    let forceValidateModel: Bool

    internal init(forceValidateModel: Bool) {
        self.forceValidateModel = forceValidateModel
    }

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
        if forceValidateModel {
            try validateModel(dataModel, in: storage)
        }

        if isStoreCompatible(in: storage, with: dataModel) { return }

        if !forceValidateModel {
            try validateModel(dataModel, in: storage)
        }
        
        let result = try resolveIncompatible(dataModel: dataModel, in: storage)
        if result == false {
            throw MigrationError.notMigrated
        }
    }

    public /*abstract*/ func validateModel(
        _ dataModel: DataModel, in storage: Storage) throws
    {
        // Implementation
    }

    public /*abstract*/ func configureStoreDescription(
        _ description: NSPersistentStoreDescription)
    {
        // Implementation
    }

    public /*abstract*/ func resolveIncompatible(
        dataModel: DataModel, in storage: Storage) throws -> Bool
    {
        // Implementation
        return false
    }
}

public /*abstract*/ class LightWeightBackupMigrationPolicy: MigrationPolicy {

    public let lightWeightEnabled: Bool

    internal init(lightWeightEnabled: Bool, forceValidateModel: Bool) {
        self.lightWeightEnabled = lightWeightEnabled
        super.init(
            forceValidateModel: forceValidateModel)
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
    internal static var defaultForceValidateModel: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    public static var error: MigrationPolicy {
        ErrorMigrationPolicy()
    }

    public static var lightWeight: MigrationPolicy {
        LightWeightMigrationPolicy()
    }

    public static func adHoc(
        migrations: Set<AdHocMigration>,
        lightWeightBackup flag: Bool = true,
        forceValidateModel: Bool? = nil) -> MigrationPolicy
    {
        AdHocMigrationPolicy(
            migrations,
            lightWeightBackup: flag,
            forceValidateModel: forceValidateModel
                ?? defaultForceValidateModel)
    }

    public static func chain(
        _ chain: MigrationChain,
        lightWeightBackup flag: Bool = true,
        forceValidateModel: Bool? = nil) -> MigrationPolicy
    {
        ChainMigrationPolicy(
            chain,
            lightWeightBackup: flag,
            forceValidateModel: forceValidateModel
                ?? defaultForceValidateModel)
    }

    public static func adHocChainComposite(
        adHoc: Set<AdHocMigration>,
        chain: MigrationChain,
        lightWeightBackup flag: Bool = true,
        forceValidateModel: Bool? = nil) -> MigrationPolicy
    {
        AdHocChainCompositeMigrationPolicy(
            adHocMigrations: adHoc,
            migrationChain: chain,
            lightWeightBackup: flag,
            forceValidateModel: forceValidateModel
                ?? defaultForceValidateModel)
    }
}

// MARK: Error

public class ErrorMigrationPolicy: LightWeightBackupMigrationPolicy {
    public init() {
        super.init(lightWeightEnabled: false, forceValidateModel: false)
    }
}

// MARK: Lightweight

public class LightWeightMigrationPolicy: LightWeightBackupMigrationPolicy {
    public init() {
        super.init(lightWeightEnabled: true, forceValidateModel: false)
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

    private var matchedMigration: AdHocMigration?

    public init(
        _ adHocMigrations: Set<AdHocMigration>,
        lightWeightBackup: Bool,
        forceValidateModel: Bool)
    {
        self.adHocMigrations = adHocMigrations
        super.init(
            lightWeightEnabled: lightWeightBackup,
            forceValidateModel: forceValidateModel)
    }

    public override func validateModel(
        _ dataModel: DataModel, in storage: Storage) throws
    {
        guard let storage = storage as? ConcreteStorage,
              let sourceName = NSPersistentStoreCoordinator
                .lastActiveVersionName(in: storage) else { return }
        matchedMigration = findCompatibleMigration(
            sourceName: sourceName, desitnationName: dataModel.name)
        if matchedMigration != nil {
            throw MigrationError.incompatible
        }
    }

    private func findCompatibleMigration(
        sourceName: String, desitnationName: String) -> AdHocMigration?
    {
        adHocMigrations
            .first {
                $0.sourceName == sourceName &&
                $0.migration.name == desitnationName
            }
    }

    public override func resolveIncompatible(
        dataModel: DataModel, in storage: Storage) throws -> Bool
    {
        guard let storage = storage as? ConcreteStorage,
              let sourceName = NSPersistentStoreCoordinator
                .lastActiveVersionName(in: storage),
              let migration = matchedMigration ?? findCompatibleMigration(
                    sourceName: sourceName, desitnationName: dataModel.name)
        else { return true }
        let migrator = AdHocMigrator(
            storage: storage, sourceModelName: sourceName,
            migration: migration.migration, dataModel: dataModel)
        return try migrator.migrate()
    }
}

// MARK: Chain

public class ChainMigrationPolicy: LightWeightBackupMigrationPolicy {

    public let migrationChain: MigrationChain

    public init(
        _ migrationChain: MigrationChain,
        lightWeightBackup: Bool,
        forceValidateModel: Bool)
    {
        self.migrationChain = migrationChain
        super.init(
            lightWeightEnabled: lightWeightBackup,
            forceValidateModel: forceValidateModel)
    }

    public override func validateModel(_ model: DataModel, in storage: Storage) throws {
        guard let managedObjectModel = try migrationChain.managedObjectModels().last else {
            throw MigrationError.incompatible
        }
        if managedObjectModel.isCompactible(with: model.managedObjectModel) == false {
            throw ChainMigratorError.migrationChainIncompatibleWithDataModel
        }
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
        ChainMigrationPolicy(
            migrationChain,
            lightWeightBackup: lightWeightEnabled,
            forceValidateModel: forceValidateModel)

    public init(
        adHocMigrations: Set<AdHocMigration>,
        migrationChain: MigrationChain,
        lightWeightBackup: Bool,
        forceValidateModel: Bool)
    {
        self.migrationChain = migrationChain
        super.init(
            adHocMigrations,
            lightWeightBackup: lightWeightBackup,
            forceValidateModel: forceValidateModel)
    }

    public override func validateModel(
        _ dataModel: DataModel, in storage: Storage) throws
    {
        do {
            try super.validateModel(dataModel, in: storage)
        } catch {
            try chainMigrationPolicy.validateModel(dataModel, in: storage)
        }
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
