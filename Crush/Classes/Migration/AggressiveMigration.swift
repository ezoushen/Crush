//
//  AggressiveMigration.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/2/4.
//

import CoreData

public protocol AggressiveMigrationMethodProtocol: class {
    func createProperty<T: AttributeProtocol & TypeStringConvertible>(name: String, type: T.Type, defaultValue: T.PropertyValue, options: [PropertyOption])
    func createRelationship<T: RelationshipProtocol>(name: String, type: T.Type, inverse: T.InverseType, options: [PropertyOption])
    func removeProperty(name: String)
    func transformProperty<T: AttributeProtocol, S: AttributeProtocol>(fromName: String, sourceType: T, toName: String, destinationType: S)
}

public protocol AggressiveMigrationProtocol: class {
    func migrate()
}

public typealias AggressiveMigration = AggressiveMigrationProtocol & AggressiveMigrationMethodProtocol

fileprivate var _contentsDict: [String: String] = [:]

extension AggressiveMigrationMethodProtocol {
    fileprivate var contents: String {
        get { _contentsDict[String(reflecting: Self.self)] ?? ""}
        set { _contentsDict[String(reflecting: Self.self)] = newValue}
    }
    
    func createProperty<T: AttributeProtocol & TypeStringConvertible>(name: String, type: T.Type, defaultValue: T.PropertyValue, options: [PropertyOption]) {
        let value = """
        \(type.typedef)(\(defaultValue.presentedAsString)\(options.isEmpty ? "" : ", options: [\(options.map{ "." + String(describing: $0) }.joined(separator: ", "))]"))
        var \(name): \(T.PropertyValue.nativeTypeName.self)
        """
        contents.append(value)
        print(value)
    }
    
    
    
    func createRelationship<T>(name: String, type: T.Type, inverse: T.InverseType, options: [PropertyOption]) where T : RelationshipProtocol {
        
    }
    
    func removeProperty(name: String) {
        
    }
    
    func transformProperty<T, S>(fromName: String, sourceType: T, toName: String, destinationType: S) where T : AttributeProtocol, S : AttributeProtocol {
        
    }
}
