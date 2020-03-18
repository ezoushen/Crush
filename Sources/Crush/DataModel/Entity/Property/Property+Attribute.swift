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

extension AttributeOption: MutablePropertyOptionProtocol {
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

public protocol AttributeProtocol: NullablePropertyProtocol where PropertyValue: FieldAttributeType {
    var defaultValue: Any? { get set }
    var attributeValueClassName: String? { get }
    init(wrappedValue: PropertyValue, options: [PropertyOptionProtocol])
}

extension AttributeProtocol where EntityType: SavableTypeProtocol {
    public var attributeType: NSAttributeType {
        PropertyValue.nativeType
    }
    
    public var attributeValueClassName: String? {
        EntityType.self is NSCoding.Type ? String(describing: Self.self) : nil
    }
    
    public var valueTransformerName: String? {
        EntityType.self is NSCoding.Type ? String(describing: DefaultTransformer.self) : nil
    }

}

extension AttributeProtocol where EntityType: SavableTypeProtocol {
    public var defaultValue: Any? { nil }
}

// MARK: - EntityAttributeType
@propertyWrapper
public final class Attribute<O: OptionalTypeProtocol>: AttributeProtocol where O.FieldType: FieldAttributeType, O.PropertyValue: FieldAttributeType {
    
    public typealias PropertyValue = O.PropertyValue
    public typealias OptionalType = O
    public typealias Option = AttributeOption
    public typealias EntityType = O.FieldType.RuntimeObjectValue
        
    public var wrappedValue: PropertyValue {
        get {
            let value: PropertyValue.ManagedObjectValue = valueMappingProxy!.getValue(property: self)
            return PropertyValue.convert(value: value)
        }
        set {
            guard let proxy = valueMappingProxy as? ReadWriteValueMapperProtocol else {
                return assertionFailure("value should not be modified with read only value mapper")
            }
            let value: PropertyValue.ManagedObjectValue = PropertyValue.convert(value: newValue)
            proxy.setValue(value, property: self)
        }
    }
    
    public var projectedValue: Attribute<O> {
        self
    }
    
    public var valueMappingProxy: ReadOnlyValueMapperProtocol? = nil
    
    public var defaultValue: Any? = nil

    public var defaultName: String = ""
    
    public var renamingIdentifier: String?
    
    public var options: [PropertyOptionProtocol] = []
    
    public var propertyCacheKey: String = ""
    
    public init() { }
    
    public func emptyPropertyDescription() -> NSPropertyDescription {
        let description = NSAttributeDescription()

        options.forEach{ $0.updatePropertyDescription(description) }

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
    
    public init(wrappedValue: PropertyValue, options: [PropertyOptionProtocol]) {
        self.defaultValue = wrappedValue
        self.options = options
    }
    
    public init(_ defaultValue: String? = nil, options: [PropertyOptionProtocol] = []) {
        self.defaultValue = defaultValue
        self.options = options
    }
}
