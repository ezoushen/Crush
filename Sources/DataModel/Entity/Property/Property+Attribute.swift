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

public protocol AttributeProtocol: NullableProperty where PredicateValue: FieldProtocol{
    var defaultValue: Any? { get set }
    var attributeValueClassName: String? { get }
    var configuration: PropertyConfiguration { get set }
    init(wrappedValue: PropertyValue, options: PropertyConfiguration)
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
@propertyWrapper
public final class Attribute<O: Nullability, FieldType: FieldAttribute & Hashable>: AttributeProtocol {
    public typealias PredicateValue = FieldType
    public typealias PropertyValue = FieldType?
    public typealias Nullability = O
    public typealias PropertyOption = AttributeOption
    
    public var wrappedValue: PropertyValue {
        get {
            FieldType.convert(value: proxy.getValue(key: description.name))
        }
        set {
            proxy.setValue(FieldType.convert(value: newValue), key: description.name)
        }
    }
    
    public var projectedValue: Attribute<O, FieldType> {
        self
    }
    
    public var proxy: PropertyProxy! = nil
    
    public var defaultValue: Any? = nil

    public var defaultName: String = ""
        
    public var configuration: PropertyConfiguration = []
    
    public var propertyCacheKey: String = ""
    
    public weak var entityObject: NeutralEntityObject?
    
    public init() { }
    
    public func emptyPropertyDescription() -> NSPropertyDescription {
        let description = NSAttributeDescription()

        configuration.configure(description: description)

        description.isTransient = isTransient
        description.valueTransformerName = valueTransformerName
        description.name = description.name.isEmpty ? defaultName : description.name
        description.defaultValue = defaultValue
        description.versionHashModifier = description.name
        description.isOptional = O.isOptional
        description.attributeType = attributeType
        
        if let className = attributeValueClassName {
            description.attributeValueClassName = className
        }
        
        return description
    }
    
    public convenience init(wrappedValue: PropertyValue) {
        self.init(wrappedValue: wrappedValue, options: [])
    }
    
    public init(wrappedValue: PropertyValue, options: PropertyConfiguration) {
        self.defaultValue = wrappedValue
        self.configuration = options
    }
}