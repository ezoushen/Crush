//
//  KeyPath+helper.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import Foundation
import CoreData

extension AnyKeyPath {
    var stringValue: String {
        return _kvcKeyPathString!
    }
}

public protocol Expressible {
    func asExpression() -> Any
}

public protocol RootTracableKeyPathProtocol: Expressible {
    var rootType: Entity.Type { get }
    var keyPath: AnyKeyPath { get }
    var fullPath: String { get }
}

public protocol PartailTracableKeyPathProtocol: RootTracableKeyPathProtocol {
    associatedtype Root: Entity
    var root: PartialKeyPath<Root> { get }
    var allPaths: [RootTracableKeyPathProtocol] { get }
}

public protocol TracableKeyPathProtocol: PartailTracableKeyPathProtocol {
    associatedtype Value: NullableProperty
}

extension PartailTracableKeyPathProtocol {
    public func asExpression() -> Any {
        fullPath
    }
    
    public var fullPath: String {
        let path = allPaths.compactMap{ keyPath -> String? in
            let runtimeObject = keyPath.rootType.dummy()
            return (runtimeObject[keyPath: keyPath.keyPath] as? PropertyProtocol)?.name
        }.joined(separator: ".")
        return path
    }
}

public class PartialTracableKeyPath<Root: Entity>: PartailTracableKeyPathProtocol {
    
    public let root: PartialKeyPath<Root>
    
    var subpaths: [RootTracableKeyPathProtocol] = []
    
    public var keyPath: AnyKeyPath {
        return root
    }
    
    public var rootType: Entity.Type {
        return Root.self
    }
    
    public var allPaths: [RootTracableKeyPathProtocol] {
        return [PartialTracableKeyPath<Root>(root)] + subpaths
    }
    
    init(_ keyPath: PartialKeyPath<Root>, subpaths: [RootTracableKeyPathProtocol] = []) {
        self.root = keyPath
        self.subpaths = subpaths
    }
}

public class TracableKeyPath<Root: Entity, Value: NullableProperty>: PartialTracableKeyPath<Root>, TracableKeyPathProtocol {
    
    public override var allPaths: [RootTracableKeyPathProtocol] {
        return [TracableKeyPath<Root, Value>(root)] + subpaths
    }
}

extension KeyPath: Expressible where Root: RuntimeObject {
    public func asExpression() -> Any {
        Value.self is PropertyProtocol.Type
            ? stringValueAsEntityObject
            : stringValueAsNSManagedObject
    }
    
    private var stringValueAsEntityObject: String {
        let dummy = (Root.self as! Entity.Type).dummy()
        return ((dummy[keyPath: self as AnyKeyPath] as? PropertyProtocol)?.name)!
    }
    
    private var stringValueAsNSManagedObject: String {
        stringValue
    }
}

extension KeyPath: RootTracableKeyPathProtocol where Root: NeutralEntityObject, Value: NullableProperty {
    public var rootType: Entity.Type {
        return Root.self
    }
    
    public var keyPath: AnyKeyPath {
        return self
    }
    
    public var fullPath: String {
        let dummy = Root.dummy()
        return dummy[keyPath: self].name
    }
}

extension KeyPath: PartailTracableKeyPathProtocol where Root: NeutralEntityObject, Value: NullableProperty {
    public var root: PartialKeyPath<Root> {
        self
    }
    
    public var allPaths: [RootTracableKeyPathProtocol] {
        return [self]
    }
}

extension KeyPath: TracableKeyPathProtocol where Root: NeutralEntityObject, Value: NullableProperty {
    
}

extension TracableKeyPathProtocol where Root: Entity, Value: NullableProperty {
    public typealias RelationshipType = Value.PredicateValue
    
    static public func + <ExtendedValue: Entity>(
        lhs: Self,
        keyPath: KeyPath<RelationshipType, ExtendedValue>
    )
        -> TracableKeyPath<Root, ExtendedValue>
        where RelationshipType: NeutralEntityObject
    {
        return TracableKeyPath<Root, ExtendedValue>(lhs.root, subpaths: [
            TracableKeyPath<RelationshipType, ExtendedValue>(keyPath)
        ])
    }
    
    static public func + <ExtendedValue: AttributeProtocol>(
        lhs: Self,
        keyPath: KeyPath<RelationshipType, ExtendedValue>
    ) -> TracableKeyPath<Root, ExtendedValue>
        where RelationshipType: NeutralEntityObject
    {
        return TracableKeyPath<Root, ExtendedValue>(lhs.root, subpaths: [
            TracableKeyPath<RelationshipType, ExtendedValue>(keyPath)
        ])
    }
}
