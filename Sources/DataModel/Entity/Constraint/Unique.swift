//
//  Unique.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/3/20.
//

import Foundation

protocol UniqueConstraintProtocol {
    var uniquenessConstarints: [String] { get }
}

public struct UniqueConstraintSet<Target: Entity, Value: ValuedProperty> {
    public let constraints: [KeyPath<Target, Value>]
}

extension UniqueConstraintSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: KeyPath<Target, Value>...) {
        constraints = elements
    }
}

@propertyWrapper
public struct CompositeUniqueConstraint<Target: Entity, Value: ValuedProperty>: UniqueConstraintProtocol {
    public var wrappedValue: UniqueConstraintSet<Target, Value>
    
    public init(wrappedValue: UniqueConstraintSet<Target, Value>) {
        self.wrappedValue = wrappedValue
    }
}

extension CompositeUniqueConstraint {
    var uniquenessConstarints: [String] {
        wrappedValue.constraints.map(\.propertyName)
    }
}

@propertyWrapper
public struct UniqueConstraint<Target: Entity, Value: ValuedProperty>: UniqueConstraintProtocol {
    
    public var wrappedValue: KeyPath<Target, Value>
    
    public init(wrappedValue: KeyPath<Target, Value>) {
        self.wrappedValue = wrappedValue
    }
}

extension UniqueConstraint {
    var uniquenessConstarints: [String] {
        [wrappedValue.propertyName]
    }
}
