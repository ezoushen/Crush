//
//  Property.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/21.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - EntityOption

public protocol PropertyConfigurable {
    var id: Int { get }
    func updatePropertyDescription<D: NSPropertyDescription>(_ description: D)
}

public protocol MutablePropertyConfigurable: PropertyConfigurable {
    associatedtype Description: NSPropertyDescription
}

public enum PropertyOption {
    /// This option will be ignored while the property is transient
    case isIndexedBySpotlight(Bool)
    case validationPredicatesWithWarnings([(NSPredicate, String)])
}

public struct PropertyConfiguration {
    let options: [PropertyConfigurable]
    
    public func contains(_ option: PropertyConfigurable) -> Bool {
        options.contains(where: { option.id == $0.id })
    }
}

extension PropertyConfiguration: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: PropertyConfigurable...) {
        options = elements
    }
    
    func configure(description: NSPropertyDescription) {
        options.forEach{ $0.updatePropertyDescription(description) }
    }
}

extension PropertyOption: MutablePropertyConfigurable {
    
    public typealias Description = NSPropertyDescription
    
    public var id: Int {
        switch self {
        case .isIndexedBySpotlight:
            return 0x100
        case .validationPredicatesWithWarnings:
            return 0x200
        }
    }
    
    public func updatePropertyDescription<D: NSPropertyDescription>(_ description: D) {
        switch self {
        case .isIndexedBySpotlight(let flag): description.isIndexedBySpotlight = flag
        case .validationPredicatesWithWarnings(let tuples):
            description.setValidationPredicates(tuples.map{$0.0}, withValidationWarnings: tuples.map{$0.1})
        }
    }
}

public protocol PropertyProtocol: AnyObject {
    var name: String { get set }    
    func createPropertyDescription() -> NSPropertyDescription
}

extension PropertyProtocol {
    public var isTransient: Bool { false }
}

// MARK: - Entity Property

public protocol ValuedProperty: PropertyProtocol {
    associatedtype PropertyOption: MutablePropertyConfigurable
    associatedtype PropertyValue
    associatedtype PredicateValue
    associatedtype Nullability: Crush.Nullability
    associatedtype FieldConvertor: FieldConvertible
    where FieldConvertor.RuntimeObjectValue == PropertyValue

    init(_ name: String)

    var isAttribute: Bool { get }
}
