//
//  File.swift
//  
//
//  Created by ezou on 2021/10/23.
//

import CoreData
import Foundation

public struct CoreDataError: Error {
    public let code: Code
    public let underlyingError: NSError

    init?(nsError: NSError) {
        guard let code = Code(rawValue: nsError.code) else { return nil }
        self.code = code
        self.underlyingError = nsError
    }

    public var key: String? {
        underlyingError.userInfo[NSValidationKeyErrorKey] as? String
            ?? underlyingError.userInfo["NSValidationKeyError"] as? String
    }

    public var value: Any? {
        underlyingError.userInfo[NSValidationValueErrorKey]
            ?? underlyingError.userInfo["NSValidationValueError"]
    }

    public var predicate: NSPredicate? {
        underlyingError.userInfo[NSValidationPredicateErrorKey] as? NSPredicate
            ?? underlyingError.userInfo["NSValidationPredicateError"] as? NSPredicate
    }

    public var localizedDescription: String? {
        underlyingError.userInfo[NSLocalizedDescriptionKey] as? String
            ?? underlyingError.userInfo["NSLocalizedDescription"] as? String
    }

    public var object: NSManagedObject? {
        underlyingError.userInfo[NSValidationObjectErrorKey] as? NSManagedObject
            ?? underlyingError.userInfo["NSValidationObjectError"] as? NSManagedObject
    }

    public var constraintConflicts: [NSConstraintConflict]? {
        underlyingError.userInfo[NSPersistentStoreSaveConflictsErrorKey] as? [NSConstraintConflict]
            ?? underlyingError.userInfo["NSPersistentStoreSaveConflictsError"] as? [NSConstraintConflict]
    }

    public var mergeConflicts: [NSMergeConflict]? {
        underlyingError.userInfo[NSPersistentStoreSaveConflictsErrorKey] as? [NSMergeConflict]
            ?? underlyingError.userInfo["NSPersistentStoreSaveConflictsError"] as? [NSMergeConflict]
    }

    public var detailedNSErrors: [NSError] {
        guard let details = underlyingError.userInfo[NSDetailedErrorsKey] as? [NSError]
                ?? underlyingError.userInfo["NSDetailedErrors"] as? [NSError] else { return [] }
        return details
    }

    public var detailedErrors: [CoreDataError] {
        detailedNSErrors.compactMap { CoreDataError(nsError: $0 as NSError) }
    }
}

extension CoreDataError {
    public enum Code: Int {
        case managedObjectValidation = 1550
        case managedObjectConstraintValidation = 1551

        case validationMultipleErrors = 1560
        case validationMissingMandatoryProperty = 1570
        case validationRelationshipLacksMinimumCount = 1580
        case validationRelationshipExceedsMaximumCount = 1590
        case validationRelationshipDeniedDelete = 1600
        case validationNumberTooLarge = 1610
        case validationNumberTooSmall = 1620
        case validationDateTooLate = 1630
        case validationDateTooSoon = 1640
        case validationInvalidDate = 1650
        case validationStringTooLong = 1660
        case validationStringTooShort = 1670
        case validationStringPatternMatching = 1680
        case validationInvalidURI = 1690

        case managedObjectContextLocking = 132000
        case persistentStoreCoordinatorLocking = 132010

        case managedObjectReferentialIntegrity = 133000
        case managedObjectExternalRelationship = 133010
        case managedObjectMerge = 133020
        case managedObjectConstraintMerge = 133021

        case persistentStoreInvalidType = 134000
        case persistentStoreTypeMismatch = 134010
        case persistentStoreIncompatibleSchema = 134020
        case persistentStoreSave = 134030
        case persistentStoreIncompleteSave = 134040
        case persistentStoreSaveConflicts = 134050

        case coreData = 134060
        case persistentStoreOperation = 134070
        case persistentStoreOpen = 134080
        case persistentStoreTimeout = 134090
        case persistentStoreUnsupportedRequestType = 134091
        case persistentStoreIncompatibleVersionHash = 134100

        case migration = 134110
        case migrationConstraintViolation = 134111
        case migrationCancelled = 134120
        case migrationMissingSourceModel = 134130
        case migrationMissingMappingModel = 134140
        case migrationManagerSourceStore = 134150
        case migrationManagerDestinationStore = 134160
        case entityMigrationPolicy = 134170

        case sqlite = 134180

        case inferredMappingModel = 134190
        case externalRecordImport = 134200

        case persistentHistoryTokenExpired = 134301
    }
}
extension CoreDataError: CustomStringConvertible {
    public var description: String {
        switch code {
        case .managedObjectValidation:
            return "Predicate \(predicate.contentDescription) of \(key.contentDescription) failed with value \(value.contentDescription). Object: \(object.contentDescription)."
        case .managedObjectMerge:
            return "Merge conflicts: \(mergeConflicts.contentDescription)."
        case .managedObjectConstraintMerge:
            return "Constraint conflicts: \(constraintConflicts.contentDescription)."
        case .validationMultipleErrors:
            return "Multiple errors: \(detailedErrors)"
        default:
            var description = underlyingError.localizedDescription
            if description.isEmpty {
                description = "\(code)"
            } else if let key = key {
                description = description.replacingOccurrences(of: "%{PROPERTY}@", with: key)
            }
            return "\(description) Object: \(object.contentDescription)"
        }
    }
}
