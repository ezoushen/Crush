//
//  NSExpression+helper.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import Foundation
import CoreData

extension NSExpression {
    @inlinable
    static func addAttribute(name: String, customValue: Bool) -> NSExpression {
        customValue
            ? NSExpression(format: "FUNCTION($entityPolicy , \"defaultValueForExistingObjectForKey:propertyMapping:source:\" , \"\(name)\" , $propertyMapping , $source)")
            : NSExpression(format: "FUNCTION($entityPolicy , \"defaultValueForKey:propertyMapping:entityMapping:manager:\" , \"\(name)\" , $propertyMapping , $entityMapping , $manager)")
    }

    @inlinable
    static func relationshipMapping(from: String, to: String) -> NSExpression {
        NSExpression(format: "FUNCTION($manager, \"destinationInstancesForSourceRelationshipNamed:sourceInstances:\" , \"\(to)\", $source.\(from))")
    }

    @inlinable
    static func attributeMapping(from: String) -> NSExpression {
        NSExpression(format: "FUNCTION($entityPolicy, \"attributeMappingOfPropertyMapping:entityMapping:manager:sourceValue:\", $propertyMapping , $entityMapping , $manager , $source.\(from))")
    }
    
    @inlinable
    static func customAttributeMapping(from: String) -> NSExpression {
        NSExpression(format: "FUNCTION($entityPolicy, \"customAttributeMappingOfPropertyMapping:entityMapping:manager:sourceValue:\", $propertyMapping , $entityMapping , $manager , $source.\(from))")
    }
    
    @inlinable
    static func customAttributeMapping(_ block: (NSManagedObject) -> Any?) -> NSExpression {
        NSExpression(format: "FUNCTION($entityPolicy, \"customAttributeMappingOfPropertyMapping:entityMapping:manager:source:\", $propertyMapping , $entityMapping , $manager , $source)")
    }

    @inlinable
    static func allSource(name: String) -> NSExpression {
        NSExpression(format: "FETCH(FUNCTION($manager, \"fetchRequestForSourceEntityNamed:predicateString:\" , \"\(name)\", \"TRUEPREDICATE\"), FUNCTION($manager, \"sourceContext\"), NO)")
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
public extension NSExpression {
    static func dateNow() -> NSExpression {
        NSExpression(format: "now()")
    }
    
    static func aggregate(toManyRelationship name: String, aggregation: DerivedAggregation) -> NSExpression {
        NSExpression(format: "\(name).@\(aggregation)")
    }

    static func aggregate(toManyRelationship name: String, property: String, aggregation: DerivedAggregation) -> NSExpression {
        NSExpression(format: "\(name).\(property).@\(aggregation)")
    }
    
    static func stringMapping(propertyName name: String, mapping: DerivedStringMapping) -> NSExpression {
        NSExpression(format: "\(mapping.rawValue)(\(name))")
    }
}
