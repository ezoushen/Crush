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
    
    public var id: Int {
        switch self {
        case .allowsExternalBinaryDataStorage:
            return 0x001
        case .preservesValueInHistoryOnDeletion:
            return 0x002
        }
    }
    
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
    var defaultValue: PropertyValue { get set }
    var attributeValueClassName: String? { get }
    var configuration: PropertyConfiguration { get set }
}

extension AttributeProtocol {
    public var attributeType: NSAttributeType {
        PredicateValue.nativeType
    }
    
    public var attributeValueClassName: String? {
        PredicateValue.self is NSCoding.Type
            ? String(describing: Self.self)
            : nil
    }
    
    public var valueTransformerName: String? {
        PredicateValue.self is NSCoding.Type
            ? String(describing: DefaultTransformer.self)
            : nil
    }
}

// MARK: - EntityAttributeType
public class Attribute<
    O: Nullability,
    F: FieldAttribute & Hashable,
    T: Transience
>:
    AttributeProtocol
{
    public typealias FieldType = F
    public typealias Transience = T
    public typealias Nullability = O
    public typealias PredicateValue = F
    public typealias PropertyValue = F.RuntimeObjectValue
    public typealias PropertyOption = AttributeOption
    public typealias FieldConvertor = F
        
    public var isAttribute: Bool {
        true
    }
    
    public var defaultValue: PropertyValue = nil

    public var name: String = ""
        
    public var configuration: PropertyConfiguration = []
    
    public var propertyCacheKey: String = ""
        
    public required init(_ name: String) {
        self.name = name
    }
    
    public init(_ name: String, defaultValue: PropertyValue = nil, options: PropertyConfiguration = []) {
        self.name = name
        self.defaultValue = defaultValue
        self.configuration = options
    }
    
    public func createPropertyDescription() -> NSPropertyDescription {
        let description = NSAttributeDescription()

        configuration.configure(description: description)

        description.isTransient = isTransient
        description.valueTransformerName = valueTransformerName
        description.name = name
        description.attributeType = attributeType
        description.isOptional = O.isOptional
        
        // Make sure not setting default value to nil
        if let value = defaultValue {
            description.defaultValue = FieldType.convert(value: value)
        }
        
        if let className = attributeValueClassName {
            description.attributeValueClassName = className
        }
        
        return description
    }
}
