//
//  KeyPath+helper.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import Foundation
import CoreData

extension AnyKeyPath: Expressible {
    public func asExpression() -> Any {
        stringValue
    }
    
    var stringValue: String {
        return _kvcKeyPathString!
    }
}

public protocol Expressible {
    func asExpression() -> Any
}

public protocol RootTracableKeyPathProtocol: Expressible {
    var rootType: NeutralEntityObject.Type { get }
    var keyPath: AnyKeyPath { get }
    var fullPath: String { get }
}

public protocol PartailTracableKeyPathProtocol: RootTracableKeyPathProtocol {
    associatedtype Root: NeutralEntityObject
    var root: PartialKeyPath<Root> { get }
    var allPaths: [RootTracableKeyPathProtocol] { get }
}

public protocol TracableKeyPathProtocol: PartailTracableKeyPathProtocol {
    associatedtype Value: NullablePropertyProtocol
}

extension PartailTracableKeyPathProtocol {
    public func asExpression() -> Any {
        fullPath
    }
    
    public var fullPath: String {
        let path = allPaths.compactMap{ keyPath -> String? in
            let runtimeObject = keyPath.rootType.dummy()
            return ((runtimeObject[keyPath: keyPath.keyPath] as? PropertyProtocol)?.description)?.name
        }.joined(separator: ".")
        return path
    }
}

public class PartialTracableKeyPath<Root: NeutralEntityObject>: PartailTracableKeyPathProtocol {
    
    public let root: PartialKeyPath<Root>
    
    var subpaths: [RootTracableKeyPathProtocol] = []
    
    public var keyPath: AnyKeyPath {
        return root
    }
    
    public var rootType: NeutralEntityObject.Type {
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

public class TracableKeyPath<Root: NeutralEntityObject, Value: NullablePropertyProtocol>: PartialTracableKeyPath<Root>, TracableKeyPathProtocol {
    
    public override var allPaths: [RootTracableKeyPathProtocol] {
        return [TracableKeyPath<Root, Value>(root)] + subpaths
    }
}

extension PartialKeyPath: RootTracableKeyPathProtocol where Root: NeutralEntityObject {
    public var rootType: NeutralEntityObject.Type {
        return Root.self
    }
    
    public var keyPath: AnyKeyPath {
        return self
    }
    
    public var fullPath: String {
        let dummy = Root.dummy()
        return (dummy[keyPath: self] as! PropertyProtocol).description.name
    }
}

extension PartialKeyPath: PartailTracableKeyPathProtocol where Root: NeutralEntityObject {
    public var root: PartialKeyPath<Root> {
        self
    }
    
    public var allPaths: [RootTracableKeyPathProtocol] {
        return [self]
    }
}

extension KeyPath: TracableKeyPathProtocol where Root: NeutralEntityObject, Value: NullablePropertyProtocol {}

extension TracableKeyPathProtocol where Root: Entity, Value: NullablePropertyProtocol {
    static public func + <ExtendedValue: Entity>(
        lhs: Self,
        keyPath: KeyPath<Value.OptionalType.FieldType.RuntimeObjectValue, ExtendedValue>
    )
        -> TracableKeyPath<Root, ExtendedValue>
        where Value.OptionalType.FieldType.RuntimeObjectValue: NeutralEntityObject
    {
        return TracableKeyPath<Root, ExtendedValue>(lhs.root, subpaths: [
            TracableKeyPath<Value.OptionalType.FieldType.RuntimeObjectValue, ExtendedValue>(keyPath)
        ])
    }
    
    static public func + <ExtendedValue: AttributeProtocol>(
        lhs: Self,
        keyPath: KeyPath<Value.OptionalType.FieldType.RuntimeObjectValue, ExtendedValue>
    ) -> TracableKeyPath<Root, ExtendedValue>
        where Value.OptionalType.FieldType.RuntimeObjectValue: NeutralEntityObject
    {
        return TracableKeyPath<Root, ExtendedValue>(lhs.root, subpaths: [
            TracableKeyPath<Value.OptionalType.FieldType.RuntimeObjectValue, ExtendedValue>(keyPath)
        ])
    }
}
