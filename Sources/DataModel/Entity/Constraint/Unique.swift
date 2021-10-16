//
//  Unique.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/3/20.
//

import Foundation

public protocol UniqueConstraintProtocol {
    var uniquenessConstarints: [String] { get }
}

public struct UniqueElement<T: Entity>: Hashable {
    public let name: String
    public init<S: ValuedProperty>(_ keyPath: KeyPath<T, S>) {
        self.name = keyPath.propertyName
    }
}

public struct UniqueConstraint<T: Entity>:
    UniqueConstraintProtocol,
    Hashable
{
    let elements: [UniqueElement<T>]
    
    public init(_ elements: UniqueElement<T>...) {
        self.elements = elements
    }
    
    public var uniquenessConstarints: [String] {
        elements.map(\.name)
    }
}
