//
//  File.swift
//  
//
//  Created by ezou on 2021/10/23.
//

import CoreData
import Foundation

extension NSError {
    func customError() -> Error {
        switch code {
        case NSValidationMultipleErrorsError:
            return MultipleValidationError(errors: errors!)
        case NSValidationMissingMandatoryPropertyError:
            return MissingMadatoryPropertyError(object: object!, key: key!)
        default:
            return self
        }
    }

    var key: String? {
        userInfo[NSValidationKeyErrorKey] as? String
    }

    var predicate: NSPredicate? {
        userInfo[NSValidationPredicateErrorKey] as? NSPredicate
    }

    var localizedDescription: String? {
        userInfo[NSLocalizedDescriptionKey] as? String
    }

    var object: NSManagedObject? {
        userInfo[NSValidationObjectErrorKey] as? NSManagedObject
    }
    
    var nsErrors: [NSError]? {
        guard let details = userInfo[NSDetailedErrorsKey] as? [NSError] else { return nil }
        return details
    }

    var errors: [Error]? {
        nsErrors?.map { $0.customError() }
    }
}

public protocol CoreDataError: Error, CustomStringConvertible {
    var object: NSManagedObject { get }
}

public struct MissingMadatoryPropertyError: CoreDataError {
    public let object: NSManagedObject
    public let key: String
    public var description: String {
        "\"\(key)\" is a required field in \(object.entity.name!)."
    }
}

public struct MultipleValidationError: CoreDataError {
    public var object: NSManagedObject {
        errors.map { $0 as NSError }.first { $0.object != nil }!.object!
    }
    
    public let errors: [Error]
    public var description: String {
        "Multiple errors, \(errors)"
    }
}
