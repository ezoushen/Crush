//
//  Property+Attribute.swift
//  Crush
//
//  Created by ezou on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - EntityAttribute

public enum AttributeOption {
    case allowsExternalBinaryDataStorage(Bool)
    case preservesValueInHistoryOnDeletion(Bool)
}

extension AttributeOption: MutablePropertyConfigurable {
    public typealias Description = NSAttributeDescription
    
    public func updatePropertyDescription<D: NSPropertyDescription>(_ description: D) {
        guard let description = description as? Description else { return }
        switch self {
        case .allowsExternalBinaryDataStorage(let flag): description.allowsExternalBinaryDataStorage = flag
        case .preservesValueInHistoryOnDeletion(let flag):
            if #available(iOS 13.0, watchOS 6.0, macOS 10.15, *) {
                description.preservesValueInHistoryOnDeletion = flag
            }
        }
    }
}

public protocol AttributeProtocol: ValuedProperty where PredicateValue: FieldAttribute & FieldConvertible {
    var defaultValue: Any? { get set }
    var attributeValueClassName: String? { get }
    var configuration: PropertyConfiguration { get set }
    init(_ name: String, defaultValue: PropertyValue, options: PropertyConfiguration)
}

extension AttributeProtocol {
    public var attributeType: NSAttributeType {
        PredicateValue.nativeType
    }
    
    public var attributeValueClassName: String? {
        PredicateValue.self is NSCoding.Type ? String(describing: Self.self) : nil
    }
    
    public var valueTransformerName: String? {
        PredicateValue.self is NSCoding.Type ? String(describing: DefaultTransformer.self) : nil
    }
}

// MARK: - EntityAttributeType
public final class Attribute<O: Nullability, FieldType: FieldAttribute & Hashable>: AttributeProtocol, ObservableProtocol {
    public typealias ObservableType = PredicateValue
    public typealias PredicateValue = FieldType
    public typealias PropertyValue = FieldType.RuntimeObjectValue
    public typealias Nullability = O
    public typealias PropertyOption = AttributeOption
    public typealias FieldConvertor = FieldType
        
    public var isAttribute: Bool {
        true
    }
    
    public var defaultValue: Any? = nil

    public var name: String = ""
        
    public var configuration: PropertyConfiguration = []
    
    public var propertyCacheKey: String = ""
        
    public init(_ name: String) {
        self.name = name
    }
    
    public convenience init(defaultValue: PropertyValue = nil, _ name: String) {
        self.init(name, defaultValue: defaultValue, options: [])
    }
    
    public init(_ name: String, defaultValue: PropertyValue = nil, options: PropertyConfiguration) {
        self.name = name
        self.defaultValue = defaultValue
        self.configuration = options
    }
    
    public func emptyPropertyDescription() -> NSPropertyDescription {
        let description = NSAttributeDescription()

        configuration.configure(description: description)

        description.isTransient = isTransient
        description.valueTransformerName = valueTransformerName
        description.name = name
        description.defaultValue = defaultValue
        description.versionHashModifier = description.name
        description.isOptional = O.isOptional
        description.attributeType = attributeType
        
        if let className = attributeValueClassName {
            description.attributeValueClassName = className
        }
        
        return description
    }
}
