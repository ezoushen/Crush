//
//  Validation.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/8/1.
//

import Foundation

public protocol ValidationProtocol {
    var anyKeyPath: AnyKeyPath { get }
    var wrappedValue: (NSPredicate, String) { get }
}

@propertyWrapper
public struct Validation<E: Entity, A: AttributeProtocol>: ValidationProtocol {
    public let keyPath: KeyPath<E, A>
    
    public var anyKeyPath: AnyKeyPath {
        keyPath
    }
    
    public let wrappedValue: (NSPredicate, String)
    
    public init(wrappedValue: (NSPredicate, String), _ keyPath: KeyPath<E, A>) {
        self.keyPath = keyPath
        self.wrappedValue = wrappedValue
    }
}
