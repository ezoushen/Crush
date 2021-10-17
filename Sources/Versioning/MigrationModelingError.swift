//
//  MigrationModelingError.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import Foundation

public enum MigrationModelingError: Error {
    // If received this error, please file an issue
    case internalTypeMismatch

    case migrationTargetNotFound(_ message: String)

    case unknownMigrationType

    case unknownDescriptionType
}
