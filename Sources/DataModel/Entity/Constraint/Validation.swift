//
//  Validation.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/8/1.
//

import Foundation

public protocol ValidationProtocol {
    var propertyName: String { get }
    var warning: String { get }
    var predicate: PropertyCondition { get }
}

public struct Validation<T: Entity>: ValidationProtocol, Hashable {
    public var propertyName: String
    public var warning: String
    public var predicate: PropertyCondition
    
    public init<S: ValuedProperty>(
        _ keyPath: KeyPath<T, S>,
        predicate: PropertyCondition,
        warnging: String)
    {
        self.propertyName = keyPath.propertyName
        self.predicate = predicate
        self.warning = warnging
    }
}
