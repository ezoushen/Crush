//
//  UserInfoKey.swift
//  
//
//  Created by ezou on 2021/10/24.
//

import Foundation

public enum UserInfoKey {
    // NSManagedObjectModel
    static let index = "Index"
    static let indexName = "IndexName"
    static let indexPredicate = "IndexPredicate"
    static let uniquenessConstraintName = "UniquenessConstraintName"

    // NSMappingModel
    static let attributeMappingFunc = "AttributeMappingFunc"

    // NSEntityDescription
    static let entityClassName = "EntityClassName"
}
