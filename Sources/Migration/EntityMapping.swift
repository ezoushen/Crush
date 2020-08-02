//
//  EntityMapping.swift
//  Crush
//
//  Created by ezou on 2019/10/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: EntityMapping Errors

enum EntityMappingError: Error {
    case versionNotFound
    case entityPropertyMismatch
    case entityTypeMismatch
}

enum EntityMappingUserInfoKey: String {
    case delegate
}

// MARK: - Entity Mapping Protocol

protocol EntityMapping {
    var sourceExpression: NSExpression { get }
    var mappingType: NSEntityMappingType { get }
    
    var inferredMappingName: String? { get }
    
    var sourceName: String? { get }
    var destinationName: String? { get }
    
    func attributeMappings(sourceModel: NSManagedObjectModel?, destinationModel: NSManagedObjectModel?) throws -> [PropertyMappingProtocol]
    func relationMappings(sourceModel: NSManagedObjectModel?, destinationModel: NSManagedObjectModel?) throws -> [PropertyMappingProtocol]
    
    func entityMapping(sourceModel: NSManagedObjectModel?, destinationModel: NSManagedObjectModel?) throws -> NSEntityMapping
}

extension EntityMapping {
    func attributeMappings(sourceModel: NSManagedObjectModel?, destinationModel: NSManagedObjectModel?) -> [PropertyMappingProtocol] { [] }
    func relationMappings(sourceModel: NSManagedObjectModel?, destinationModel: NSManagedObjectModel?) -> [PropertyMappingProtocol] { [] }
}

extension EntityMapping where Self: MappingModelMergeDelegate {
    var sourceExpression: NSExpression {
        NSExpression(format: "FETCH(FUNCTION($manager, 'fetchRequestForSourceEntityNamed:predicateString:' , '\(sourceName ?? "")', 'TRUEPREDICATE'), FUNCTION($manager, 'sourceContext'), NO)")
    }
    
    func entityMapping(sourceModel: NSManagedObjectModel?, destinationModel: NSManagedObjectModel?) throws -> NSEntityMapping {
        let entityMapping = NSEntityMapping()
        entityMapping.name = "transfrom\(sourceName ?? "")To\(destinationName ?? "")"
        entityMapping.sourceEntityName = sourceName
        entityMapping.sourceExpression = sourceExpression
        entityMapping.sourceEntityVersionHash = sourceModel?.entityVersionHashesByName[sourceName ?? ""]
        entityMapping.destinationEntityName = destinationName
        entityMapping.destinationEntityVersionHash = destinationModel?.entityVersionHashesByName[destinationName ?? ""]
        entityMapping.mappingType = mappingType
        entityMapping.attributeMappings = try attributeMappings(sourceModel: sourceModel, destinationModel: destinationModel).map{ $0.propertyMapping }
        entityMapping.relationshipMappings = try relationMappings(sourceModel: sourceModel, destinationModel: destinationModel).map{ $0.propertyMapping }
        entityMapping.userInfo = entityMapping.userInfo ?? [:]
        entityMapping.userInfo?[EntityMappingUserInfoKey.delegate] = self
        return entityMapping
    }
}

enum EntityMappingType {
    case add, remove, transform, copy
    
    func name(from type: String)-> String {
        switch self {
        case .add:          return "IEM_Add_\(type)"
        case .remove:       return "IEM_Remove_\(type)"
        case .transform:    return "IEM_Transform_\(type)"
        case .copy:         return "IEM_Copy_\(type)"
        }
    }
    
    var type: NSEntityMappingType {
        switch self {
        case .add: return .addEntityMappingType
        case .remove: return .removeEntityMappingType
        case .transform: return .transformEntityMappingType
        case .copy: return .copyEntityMappingType
        }
    }
    
    func didMergeMappingModel(source: String, destination: String, mappingModel: NSMappingModel) {
        guard self == .transform else { return }
        let candidateNames = source == destination
            ? ["IEM_Transform_\(source)"]
            : ["IEM_Remove_\(source)", "IEM_Add_\(destination)"]
        
        let entityMappings = mappingModel.entityMappings.filter{ !candidateNames.contains($0.name) }
        mappingModel.entityMappings = entityMappings
    }
}

public struct AnyEntityMapping: EntityMapping, MappingModelMergeDelegate {
    var mappingType: NSEntityMappingType {
        type.type
    }
    
    var inferredMappingName: String?
    
    var sourceName: String?
    
    var destinationName: String?
    
    let attributes: [PropertyMappingProtocol]
    let relations: [PropertyMappingProtocol]
    
    private let type: EntityMappingType
    
    init(type: EntityMappingType, source: String, destination: String, attributes: [PropertyMappingProtocol], relations: [PropertyMappingProtocol]) {
        self.type = type
        self.inferredMappingName = type.name(from: source)
        self.sourceName = source
        self.destinationName = destination
        self.attributes = attributes
        self.relations = relations
    }
    
    func attributeMappings(sourceModel: NSManagedObjectModel?, destinationModel: NSManagedObjectModel?) -> [PropertyMappingProtocol] {
        return attributes
    }
    
    func relationMappings(sourceModel: NSManagedObjectModel?, destinationModel: NSManagedObjectModel?) -> [PropertyMappingProtocol] {
        return relations
    }
    
    func didMergeMappingModel(mappingModel: NSMappingModel) {
        type.didMergeMappingModel(source: sourceName!, destination: destinationName!, mappingModel: mappingModel)
    }
}

// MARK: Add Entity Mapping

public struct AddEntityMapping<T: Entity>: EntityMapping, MappingModelMergeDelegate {
    typealias FromType = T
    typealias ToType = T
    
    var mappingType: NSEntityMappingType {
        return .addEntityMappingType
    }
    
    var sourceName: String? {
        return nil
    }
    
    var destinationName: String? {
        T.fetchKey
    }
    
    var sourceModel: NSManagedObjectModel? {
        return nil
    }
    
    var inferredMappingName: String? {
        "IEM_Add_\(T.fetchKey)"
    }
}

// MARK: - Remove Entity Mapping

public struct RemoveEntityMapping<T: Entity>: EntityMapping, MappingModelMergeDelegate {
    typealias FromType = T
    typealias ToType = T
    
    var mappingType: NSEntityMappingType {
        return .removeEntityMappingType
    }
    
    var sourceName: String? {
        T.fetchKey
    }
    
    var destinationName: String? {
        return nil
    }
    
    var destinationModel: NSManagedObjectModel? {
        return nil
    }
    
    var inferredMappingName: String? {
        "IEM_Remove_\(T.fetchKey)"
    }
}

// MARK: - Transform Entity Mapping

public struct TransformEntityMapping<T: Entity, S: Entity>: EntityMapping, MappingModelMergeDelegate {
    typealias FromType = T
    typealias ToType = S
    
    var mappingType: NSEntityMappingType {
        return .transformEntityMappingType
    }
    
    var sourceName: String? {
        T.fetchKey
    }
    
    var destinationName: String? {
        S.fetchKey
    }
    
    var inferredMappingName: String? {
        sourceName == destinationName ? "IEM_Transform_\(T.fetchKey)" : nil
    }
    
    private let _attributeMappings: [AttributeMapping<T, S>]
    private let _relationshipMappings: [RelationshipMapping<T, S>]
    
    func attributeMappings(sourceModel: NSManagedObjectModel?, destinationModel: NSManagedObjectModel?) -> [PropertyMappingProtocol] {
        return _attributeMappings
    }
    
    func relationMappings(sourceModel: NSManagedObjectModel?, destinationModel: NSManagedObjectModel?) -> [PropertyMappingProtocol] {
        return _relationshipMappings
    }
    
    init(attributeMappings: [AttributeMapping<T, S>] = [], relationshipMappings: [RelationshipMapping<T,S>] = []) {
        self._attributeMappings = attributeMappings
        self._relationshipMappings = relationshipMappings
    }
    
    func didMergeMappingModel(mappingModel: NSMappingModel) {
        let candidateNames = T.fetchKey == S.fetchKey
            ? ["IEM_Transform_\(T.fetchKey)"]
            : ["IEM_Remove_\(T.fetchKey)", "IEM_Add_\(S.fetchKey)"]
        
        let entityMappings = mappingModel.entityMappings.filter{ !candidateNames.contains($0.name) }
        mappingModel.entityMappings = entityMappings
    }
}

// MARK: - Custom Entity Mapping

public struct CustomEntityMapping<T: Entity, S: Entity>: EntityMapping, MappingModelMergeDelegate {
    typealias FromType = T
    typealias ToType = S
    
    var mappingType: NSEntityMappingType {
        return .copyEntityMappingType
    }
    
    var sourceName: String? {
        T.fetchKey
    }
    
    var destinationName: String? {
        T.fetchKey
    }
    
    var inferredMappingName: String? {
        nil
    }
}

// MARK: - Copy Entity Mapping

public struct CopyEntityMapping<T: Entity, S: Entity>: EntityMapping, MappingModelMergeDelegate {
    typealias FromType = T
    typealias ToType = S
    
    var mappingType: NSEntityMappingType {
        return .customEntityMappingType
    }
    
    var sourceName: String? {
        T.fetchKey
    }
    
    var destinationName: String? {
        S.fetchKey
    }
    
    var inferredMappingName: String? {
        "IEM_Copy_\(T.fetchKey)"
    }
    
    func createPropertyMappings<D: PropertyMappingProtocol>(sourceEntity: NSEntityDescription, destinationEntity: NSEntityDescription) throws -> [D] {
        guard destinationEntity.attributesByName.keys == sourceEntity.attributesByName.keys else {
            throw EntityMappingError.entityPropertyMismatch
        }

        return zip(sourceEntity.attributesByName.sorted{ $0.key < $1.key}, destinationEntity.attributesByName.sorted{ $0.key < $1.key})
            .map {
                D.init(from: $0.0.value.name, to: $0.1.value.name)
            }
    }
    
    func attributeMappings(sourceModel: NSManagedObjectModel?, destinationModel: NSManagedObjectModel?) throws -> [PropertyMappingProtocol] {
        guard let destinationEntity = destinationModel?.entitiesByName[destinationName ?? ""],
              let sourceEntity = sourceModel?.entitiesByName[sourceName ?? ""] else {
            throw EntityMappingError.versionNotFound
        }

        let attributeMappings: [AttributeMapping<T,S>] = try createPropertyMappings(sourceEntity: sourceEntity, destinationEntity: destinationEntity)
        return attributeMappings
    }
    
    func relationMappings(sourceModel: NSManagedObjectModel?, destinationModel: NSManagedObjectModel?) throws -> [PropertyMappingProtocol] {
        guard let destinationEntity = destinationModel?.entitiesByName[destinationName ?? ""],
              let sourceEntity = sourceModel?.entitiesByName[sourceName ?? ""] else {
            throw EntityMappingError.versionNotFound
        }

        let relationshipMappings: [RelationshipMapping<T, S>] = try createPropertyMappings(sourceEntity: sourceEntity, destinationEntity: destinationEntity)

        return relationshipMappings
    }
}
