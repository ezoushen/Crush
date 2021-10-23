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

    var errors: [Error]? {
        guard let details = userInfo[NSDetailedErrorsKey] as? [NSError] else { return nil }
        return details.map { $0.customError() }
    }
}

public protocol CoreDataError: Error {
    var object: NSManagedObject { get }
}

public struct MissingMadatoryPropertyError: CoreDataError, CustomStringConvertible {
    public let object: NSManagedObject
    public let key: String
    public var description: String {
        "\"\(key)\" is a required field."
    }
}
