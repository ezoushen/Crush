//
//  MigrationPolicy.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import Foundation
import CoreData

/// A policy for migrating data models in a Core Data persistent store.
/// `MigrationPolicy` is an abstract class that provides a set of methods and properties for managing migrations of data
/// models in a Core Data persistent store. It contains a set of abstract methods that must be implemented by its subclasses to define a specific migration policy.
///
/// This class provides a default implementation of a policy for checking if a persistent store is compatible with a given data model,
/// and for validating a data model against a persistent store. It also defines methods for configuring the migration process and for resolving incompatibilities between a data model and a persistent store.
///
/// `MigrationPolicy` is not intended to be instantiated directly. Instead, you should create a subclass of MigrationPolicy to define a specific migration policy for your application.
///
/// To create a subclass of MigrationPolicy, you must override the abstract methods of this class to implement your specific migration policy.
///
/// The methods that **must** be implemented by a subclass of `MigrationPolicy` are:
///
/// - validateModel(_:in:)
/// - configureStoreDescription(_:)
/// - resolveIncompatible(dataModel:in:)
///
public /* abstract */ class MigrationPolicy {
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
                    "Migration of \(Self.self) ends with error: \(error), will try to perform lightweight migration later if migration is needed")
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

    /// Returns a migration policy that throws an error if the store is not compatible with the data model.
    public static var error: MigrationPolicy {
        ErrorMigrationPolicy()
    }

    /// Returns a migration policy for lightweight migration.
    public static var lightWeight: MigrationPolicy {
        LightWeightMigrationPolicy()
    }

    /// Returns a migration policy to migrate the persistent store from one specific version to another.
    ///
    /// - Parameters:
    ///   - migrations: The supported ad-hoc migration models.
    ///   - lightWeightBackup: A Boolean value indicating whether to use light weight migration if no supported ad-hoc migration model matched.
    ///   - forceValidateModel: A Boolean value indicating whether to check if the persistent store is compatible with any available model resolved from `migrations`, regardless of the value of `lightWeightBackup`.
    public static func adHoc(
        migrations: Set<AdHocMigration>,
        lightWeightBackup: Bool = true,
        forceValidateModel: Bool? = nil) -> MigrationPolicy
    {
        AdHocMigrationPolicy(
            migrations,
            lightWeightBackup: lightWeightBackup,
            forceValidateModel: forceValidateModel ?? defaultForceValidateModel)
    }

    /// Returns a migration policy to migrate the persistent store changes incrementally.
    ///
    /// - Parameters:
    ///   - chain: The incremental changes of the data model.
    ///   - lightWeightBackup: A Boolean value indicating whether to use light weight migration if no supported ad-hoc migration model matched.
    ///   - forceValidateModel: A Boolean value indicating whether to check if the persistent store is compatible with any available model resolved from `chain`, regardless of the value of `lightWeightBackup`.
    public static func incremental(
        _ chain: MigrationChain,
        lightWeightBackup: Bool = true,
        forceValidateModel: Bool? = nil) -> MigrationPolicy
    {
        IncrementalMigrationPolicy(
            chain,
            lightWeightBackup: lightWeightBackup,
            forceValidateModel: forceValidateModel ?? defaultForceValidateModel)
    }


    /// If no ad-hoc migration model matched, try migrate the persistent store by incremental changes
    /// 
    /// - Parameters:
    ///   - adHoc: The supported ad-hoc migration models.
    ///   - chain: The incremental changes of the data model.
    ///   - lightWeightBackup: A Boolean value indicating whether to use light weight migration if no supported ad-hoc migration model matched.
    ///   - forceValidateModel: A Boolean value indicating whether to check if the persistent store is compatible with any available model resolved from `chain`, regardless of the value of `lightWeightBackup
    public static func composite(
        adHoc: Set<AdHocMigration>,
        chain: MigrationChain,
        lightWeightBackup: Bool = true,
        forceValidateModel: Bool? = nil) -> MigrationPolicy
    {
        CompositeMigrationPolicy(
            adHocMigrations: adHoc,
            migrationChain: chain,
            lightWeightBackup: lightWeightBackup,
            forceValidateModel: forceValidateModel ?? defaultForceValidateModel)
    }
}

// MARK: Error

class ErrorMigrationPolicy: LightWeightBackupMigrationPolicy {
    init() {
        super.init(lightWeightEnabled: false, forceValidateModel: false)
    }
}

// MARK: Lightweight

class LightWeightMigrationPolicy: LightWeightBackupMigrationPolicy {
    init() {
        super.init(lightWeightEnabled: true, forceValidateModel: false)
    }

    override func resolveIncompatible(
        dataModel: DataModel, in storage: Storage) throws -> Bool
    {
        true
    }
}

// MARK: AdHoc

class AdHocMigrationPolicy: LightWeightBackupMigrationPolicy {

    let adHocMigrations: Set<AdHocMigration>

    private var matchedMigration: AdHocMigration?

    init(
        _ adHocMigrations: Set<AdHocMigration>,
        lightWeightBackup: Bool,
        forceValidateModel: Bool)
    {
        self.adHocMigrations = adHocMigrations
        super.init(
            lightWeightEnabled: lightWeightBackup,
            forceValidateModel: forceValidateModel)
    }

    override func validateModel(
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

    override func resolveIncompatible(
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

class IncrementalMigrationPolicy: LightWeightBackupMigrationPolicy {

    let migrationChain: MigrationChain

    init(
        _ migrationChain: MigrationChain,
        lightWeightBackup: Bool,
        forceValidateModel: Bool)
    {
        self.migrationChain = migrationChain
        super.init(
            lightWeightEnabled: lightWeightBackup,
            forceValidateModel: forceValidateModel)
    }

    override func validateModel(_ model: DataModel, in storage: Storage) throws {
        guard let managedObjectModel = try migrationChain.managedObjectModels().last else {
            throw MigrationError.incompatible
        }
        if managedObjectModel.isCompactible(with: model.managedObjectModel) == false {
            throw ChainMigratorIncompatibleModelError(
                incrementalModel: managedObjectModel,
                targetModel: model.managedObjectModel)
        }
    }

    override func resolveIncompatible(
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

class CompositeMigrationPolicy: AdHocMigrationPolicy {
    let migrationChain: MigrationChain
    private lazy var chainMigrationPolicy =
        IncrementalMigrationPolicy(
            migrationChain,
            lightWeightBackup: lightWeightEnabled,
            forceValidateModel: forceValidateModel)

    init(
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

    override func validateModel(
        _ dataModel: DataModel, in storage: Storage) throws
    {
        do {
            try super.validateModel(dataModel, in: storage)
        } catch {
            try chainMigrationPolicy.validateModel(dataModel, in: storage)
        }
    }

    override func resolveIncompatible(
        dataModel: DataModel, in storage: Storage) throws -> Bool
    {
        if try super.resolveIncompatible(dataModel: dataModel, in: storage) {
            return true
        }
        return try chainMigrationPolicy.resolveIncompatible(
            dataModel: dataModel, in: storage)
    }
}
