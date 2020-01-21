//
//  PropertyMapping.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/1/14.
//  Copyright © 2020 ezou. All rights reserved.
//

import CoreData

// MARK: - Property Mapping Protocol

protocol PropertyMappingProtocol {
    var valueExpression: NSExpression { get }
    var destinationKeyPath: String { get }
    var sourceKeyPath: String { get }
    var propertyMapping: NSPropertyMapping { get }
    
    init(from source: String, to destination: String)
    
    func extractProperties(entityDescription: NSEntityDescription) -> [String: NSPropertyDescription]
}

extension PropertyMappingProtocol {
    var propertyMapping: NSPropertyMapping {
        let mapping = NSPropertyMapping()
        mapping.name = destinationKeyPath
        mapping.valueExpression = valueExpression
        return mapping
    }
}

// MARK: - Attribute Mapping

enum PropertyMappingType {
    case attribute, relationship
    
    func valueExpression(source sourceKeyPath: String, destination destinationKeyPath: String) -> NSExpression {
        switch self {
        case .relationship:
            let selector = sourceKeyPath.contains(".") ? "valueForKeyPath" : "valueForKey"
            return NSExpression(format: "FUNCTION($manager, 'destinationInstancesForSourceRelationshipNamed:sourceInstances:' , '\(destinationKeyPath)', FUNCTION($source, '\(selector):' , '\(sourceKeyPath)'))")
        case .attribute:
            let selector = sourceKeyPath.contains(".") ? "valueForKeyPath" : "valueForKey"
            return NSExpression(format: "FUNCTION($source, '\(selector):' , '\(sourceKeyPath)')")
        }
    }
    
    func extractProperties(entityDescription: NSEntityDescription) -> [String : NSPropertyDescription] {
        switch self {
        case .attribute: return entityDescription.attributesByName
        case .relationship: return entityDescription.relationshipsByName
        }
    }
}

struct AnyPropertyMapping: PropertyMappingProtocol {
    var valueExpression: NSExpression {
        type.valueExpression(source: sourceKeyPath, destination: destinationKeyPath)
    }
    
    var destinationKeyPath: String
    
    var sourceKeyPath: String
    
    let type: PropertyMappingType
    
    init(from source: String, to destination: String) {
        self.sourceKeyPath = source
        self.destinationKeyPath = destination
        self.type = .attribute
    }
    
    init(type: PropertyMappingType, from source: String, to destination: String) {
        self.type = type
        self.sourceKeyPath = source
        self.destinationKeyPath = destination
    }
    
    func extractProperties(entityDescription: NSEntityDescription) -> [String : NSPropertyDescription] {
        return type.extractProperties(entityDescription: entityDescription)
    }
}

struct AttributeMapping<T: RuntimeObjectProtocol, S: RuntimeObjectProtocol>: PropertyMappingProtocol {
    
    var destinationKeyPath: String
    
    var sourceKeyPath: String
    
    var valueExpression: NSExpression {
        let selector = sourceKeyPath.contains(".") ? "valueForKeyPath" : "valueForKey"
        return NSExpression(format: "FUNCTION($source, '\(selector):' , '\(sourceKeyPath)')")
    }

    init(from source: String, to destination: String) {
        sourceKeyPath = source
        destinationKeyPath = destination
    }
    
    init<D: TracableKeyPathProtocol, W: TracableKeyPathProtocol>(fromKeyPath: D, toKeyPath: W) where D.Root == T, W.Root == S, D.Value: AttributeProtocol, W.Value: AttributeProtocol {
        sourceKeyPath = fromKeyPath.fullPath
        destinationKeyPath = toKeyPath.fullPath
    }
    
    func extractProperties(entityDescription: NSEntityDescription) -> [String: NSPropertyDescription] {
        return entityDescription.attributesByName
    }
}

// MARK: - Relationship Mapping

struct RelationshipMapping<T: RuntimeObjectProtocol, S: RuntimeObjectProtocol>: PropertyMappingProtocol {
    var valueExpression: NSExpression {
        let selector = sourceKeyPath.contains(".") ? "valueForKeyPath" : "valueForKey"
        return NSExpression(format: "FUNCTION($manager, 'destinationInstancesForSourceRelationshipNamed:sourceInstances:' , '\(destinationKeyPath)', FUNCTION($source, '\(selector):' , '\(sourceKeyPath)'))")
    }
    
    var destinationKeyPath: String
    
    var sourceKeyPath: String
    
    init(from source: String, to destination: String) {
        sourceKeyPath = source
        destinationKeyPath = destination
    }
    
    init<D: TracableKeyPathProtocol, W: TracableKeyPathProtocol>(fromKeyPath: D, toKeyPath: W) where D.Root == T, W.Root == S, D.Value: RelationshipProtocol, W.Value: RelationshipProtocol {
        
        sourceKeyPath = fromKeyPath.fullPath
        destinationKeyPath = toKeyPath.fullPath
    }
    
    func extractProperties(entityDescription: NSEntityDescription) -> [String: NSPropertyDescription] {
        return entityDescription.relationshipsByName
    }
}
