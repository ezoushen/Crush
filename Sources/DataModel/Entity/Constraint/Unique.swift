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

public struct UniqueConstraintSet<Target: Entity> {
    public let constraints: [PartialKeyPath<Target>]
}

extension UniqueConstraintSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: PartialKeyPath<Target>...) {
        constraints = elements
    }
}

@propertyWrapper
public struct CompositeUniqueConstraint<Target: Entity>: UniqueConstraintProtocol {
    public var wrappedValue: UniqueConstraintSet<Target>
    
    public init(wrappedValue: UniqueConstraintSet<Target>) {
        self.wrappedValue = wrappedValue
    }
}

extension CompositeUniqueConstraint {
    var uniquenessConstarints: [String] {
        let entity = Target.dummy()
        return wrappedValue.constraints.compactMap {
            (entity[keyPath: $0] as? PropertyProtocol)?.name
        }
    }
}

@propertyWrapper
public struct UniqueConstraint<Target: Entity>: UniqueConstraintProtocol {
    
    public var wrappedValue: PartialKeyPath<Target>
    
    public init(wrappedValue: PartialKeyPath<Target>) {
        self.wrappedValue = wrappedValue
    }
}

extension UniqueConstraint {
    var uniquenessConstarints: [String] {
        [(Target.dummy()[keyPath: wrappedValue] as? PropertyProtocol)?.name].compactMap{ $0 }
    }
}
