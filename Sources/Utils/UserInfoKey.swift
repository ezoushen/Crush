//
//  UserInfoKey.swift
//  
//
//  Created by ezou on 2021/10/24.
//

import Foundation

public enum UserInfoKey {
    // NSManagedObjectModel
    static let indexes = "Index"
    static let uniquenessConstraintName = "UniquenessConstraintName"

    // NSMappingModel
    static let attributeMappingFunc = "AttributeMappingFunc"
    static let defaultValueFunc = "DefaultValueFunc"

    // NSEntityDescription
    static let entityClassName = "EntityClassName"
}
