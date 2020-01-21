//
//  MappingModelMerger.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/1/14.
//  Copyright © 2020 ezou. All rights reserved.
//

import CoreData

// MARK: - Mapping Model Merge Delegates

protocol MappingModelMergeDelegate {
    func didMergeMappingModel(mappingModel: NSMappingModel)
}

extension MappingModelMergeDelegate {
    func didMergeMappingModel(mappingModel: NSMappingModel) { }
}

// MARK: Mapping Model Merge error

enum MappingModelMergeError: Error {
    case illegalMergeTarget
}

// MARK: Mapping Model Merger

protocol MappingModelMerger {
    func mergeMappingModel(inferredMappingModel: NSMappingModel, mappingModel: NSMappingModel) throws -> NSMappingModel
}

extension MappingModelMerger {
    func mergeMappingModel(inferredMappingModel: NSMappingModel, mappingModel: NSMappingModel) throws -> NSMappingModel {
        let entityMappings: [NSEntityMapping] = mappingModel.entityMappings ?? []
        mappingModel.entityMappings = try entityMappings.map { entityMapping in
            guard let delegate = entityMapping.userInfo?[EntityMappingUserInfoKey.delegate] as? (EntityMapping & MappingModelMergeDelegate) else {
                throw MappingModelMergeError.illegalMergeTarget
            }
            
            defer {
                delegate.didMergeMappingModel(mappingModel: inferredMappingModel)
            }
            
            let name = delegate.inferredMappingName
            let inferredEntityMapping = inferredMappingModel.entityMappingsByName[name ?? ""]
            return mergeEntityMapping(inferredMapping: inferredEntityMapping, entityMapping: entityMapping)
        }
        
        mappingModel.entityMappings += inferredMappingModel.entityMappings
        
        return mappingModel
    }
    
    private func mergeEntityMapping(inferredMapping: NSEntityMapping?, entityMapping: NSEntityMapping) -> NSEntityMapping {
        guard let inferredMapping = inferredMapping else { return entityMapping }
        
        func createPropertiesByName(properties: [NSPropertyMapping]) -> [String: NSPropertyMapping] {
            var dict = Dictionary<String, NSPropertyMapping>(minimumCapacity: properties.count)
            
            properties.forEach {
                guard let name = $0.name else { return }
                dict[name] = $0
            }
            
            return dict
        }
        
        func isTheCandidate(propertiesByName: [String: NSPropertyMapping]) -> (NSPropertyMapping) -> Bool {
            return { mapping in
                guard let name = mapping.name else { return false }
                return propertiesByName[name] == nil
            }
        }
        
        let attributeMappingsByName = createPropertiesByName(properties: entityMapping.attributeMappings ?? [])
        let attributeCandidates = inferredMapping.attributeMappings?.filter(isTheCandidate(propertiesByName: attributeMappingsByName)) ?? []
        entityMapping.attributeMappings = (entityMapping.attributeMappings ?? []) + attributeCandidates
        
        let relationshipMappingsByName = createPropertiesByName(properties: entityMapping.relationshipMappings ?? [])
        let relationshipCandidates = inferredMapping.relationshipMappings?.filter(isTheCandidate(propertiesByName: relationshipMappingsByName)) ?? []
        entityMapping.relationshipMappings = (entityMapping.relationshipMappings ?? []) + relationshipCandidates
        
        return entityMapping
    }
}
