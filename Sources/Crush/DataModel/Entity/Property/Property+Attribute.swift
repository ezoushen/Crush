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

public protocol AttributeProtocol: NullablePropertyProtocol where PredicateValue: SavableTypeProtocol{
    var defaultValue: Any? { get set }
    var attributeValueClassName: String? { get }
    init(wrappedValue: PropertyValue, options: [PropertyOptionProtocol])
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
public final class Attribute<O: OptionalTypeProtocol, FieldType: FieldAttributeType>: AttributeProtocol {
    public typealias PredicateValue = FieldType
    public typealias PropertyValue = FieldType?
    public typealias OptionalType = O
    public typealias Option = AttributeOption
        
    public var wrappedValue: PropertyValue {
        get {
            let value: FieldType.ManagedObjectValue = proxy!.getValue(property: self)
            return FieldType.convert(value: value, proxyType: proxy.proxyType)
        }
        set {
            guard let proxy = proxy as? ReadWritePropertyProxy else {
                return assertionFailure("value should not be modified with read only value mapper")
            }
            let value: FieldType.ManagedObjectValue = FieldType.convert(value: newValue, proxyType: proxy.proxyType)
            proxy.setValue(value, property: self)
        }
    }
    
    public var projectedValue: Attribute<O, FieldType> {
        self
    }
    
    public weak var proxy: PropertyProxy! = nil
    
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
}
