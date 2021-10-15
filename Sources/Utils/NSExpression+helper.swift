//
//  File.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import Foundation

extension NSExpression {
    @inlinable
    static func relationshipMapping(from: String, to: String) -> NSExpression {
        NSExpression(format: "FUNCTION($manager, 'destinationInstancesForSourceRelationshipNamed:sourceInstances:' , '\(to)', FUNCTION($source, 'valueForKey' , '\(from)'))")
    }

    @inlinable
    static func attributeMapping(from: String) -> NSExpression {
        NSExpression(format: "FUNCTION($entityPolicy, '_nonNilValueOrDefaultValueForAttribute:source:destination:' , '\(from)', $source, $destination)")
    }

    @inlinable
    static func allSource(name: String) -> NSExpression {
        NSExpression(format: "FETCH(FUNCTION($manager, 'fetchRequestForSourceEntityNamed:predicateString:' , '\(name)', 'TRUEPREDICATE'), FUNCTION($manager, 'sourceContext'), NO)")
    }
}
