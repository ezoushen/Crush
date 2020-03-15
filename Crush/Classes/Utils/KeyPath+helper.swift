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
    var stringValue: String? {
        return _kvcKeyPathString
    }
}

public protocol TracableProtocol {
    var rootType: Entity.Type { get }
    var expression: Any { get }
}

public protocol RootTracableKeyPathProtocol: TracableProtocol {
    var keyPath: AnyKeyPath { get }
    var fullPath: String { get }
}

public protocol PartailTracableKeyPathProtocol: RootTracableKeyPathProtocol {
    associatedtype Root: Entity
    var root: PartialKeyPath<Root> { get }
    var allPaths: [RootTracableKeyPathProtocol] { get }
}

public protocol TracableKeyPathProtocol: PartailTracableKeyPathProtocol {
    associatedtype Value: NullablePropertyProtocol
}

extension PartailTracableKeyPathProtocol {
    public var expression: Any {
        return fullPath
    }
    
    public var fullPath: String {
        let path = allPaths.compactMap{ keyPath -> String? in
            let runtimeObject = keyPath.rootType.dummy()
            return ((runtimeObject[keyPath: keyPath.keyPath] as? PropertyProtocol)?.description)?.name
        }.joined(separator: ".")
        return path
    }
}

extension PartailTracableKeyPathProtocol where Root: NSManagedObject {
    public var fullPath: String {
        return allPaths.compactMap{ $0.keyPath.stringValue }.joined(separator: ".")
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

public class TracableKeyPath<Root: Entity, Value: NullablePropertyProtocol>: PartialTracableKeyPath<Root>, TracableKeyPathProtocol {
    
    public override var allPaths: [RootTracableKeyPathProtocol] {
        return [TracableKeyPath<Root, Value>(root)] + subpaths
    }
}

extension PartialKeyPath: TracableProtocol where Root: Entity {
    public var rootType: Entity.Type {
        return Root.self
    }
}

extension PartialKeyPath: RootTracableKeyPathProtocol where Root: Entity {
    public var keyPath: AnyKeyPath {
        return self
    }
}

extension PartialKeyPath: PartailTracableKeyPathProtocol where Root: Entity {
    public var root: PartialKeyPath<Root> {
        self
    }
    
    public var allPaths: [RootTracableKeyPathProtocol] {
        return [self]
    }
}

extension KeyPath: TracableKeyPathProtocol where Root: Entity, Value: NullablePropertyProtocol {}

extension TracableKeyPathProtocol where Root: Entity, Value: NullablePropertyProtocol {
    static public func + <ExtendedValue: Entity>(
        lhs: Self,
        keyPath: KeyPath<Value.OptionalType.FieldType.RuntimeObjectValue, ExtendedValue>
    )
        -> TracableKeyPath<Root, ExtendedValue>
        where Value.OptionalType.FieldType.RuntimeObjectValue: Entity
    {
        return TracableKeyPath<Root, ExtendedValue>(lhs.root, subpaths: [
            TracableKeyPath<Value.OptionalType.FieldType.RuntimeObjectValue, ExtendedValue>(keyPath)
        ])
    }
    
    static public func + <ExtendedValue: AttributeProtocol>(
        lhs: Self,
        keyPath: KeyPath<Value.OptionalType.FieldType.RuntimeObjectValue, ExtendedValue>
    ) -> TracableKeyPath<Root, ExtendedValue>
        where Value.OptionalType.FieldType.RuntimeObjectValue: Entity
    {
        return TracableKeyPath<Root, ExtendedValue>(lhs.root, subpaths: [
            TracableKeyPath<Value.OptionalType.FieldType.RuntimeObjectValue, ExtendedValue>(keyPath)
        ])
    }
}
