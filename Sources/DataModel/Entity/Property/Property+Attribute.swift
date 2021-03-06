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

public protocol AttributeProtocol: NullableProperty where PredicateValue: FieldAttribute & FieldConvertible {
    var defaultValue: Any? { get set }
    var attributeValueClassName: String? { get }
    var configuration: PropertyConfiguration { get set }
    init(wrappedValue: PropertyValue, _ name: String, options: PropertyConfiguration)
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
public final class Attribute<O: Nullability, FieldType: FieldAttribute & Hashable>: AttributeProtocol, ObservableProtocol {
    public typealias ObservableType = PredicateValue
    public typealias PredicateValue = FieldType
    public typealias PropertyValue = FieldType.RuntimeObjectValue
    public typealias Nullability = O
    public typealias PropertyOption = AttributeOption
    public typealias FieldConvertor = FieldType
    
    @available(*, unavailable)
    public var wrappedValue: PropertyValue {
      get { fatalError("only works on instance properties of classes") }
      set { fatalError("only works on instance properties of classes") }
    }
    
    public static subscript<EnclosingSelf: HashableEntity>(
        _enclosingInstance observed: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, PropertyValue>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Attribute<O, FieldType>>
    ) -> PropertyValue {
        get {
            let property = observed[keyPath: storageKeyPath]
            return FieldType.convert(value: observed.getValue(key: property.name))
        }
        set {
            let property = observed[keyPath: storageKeyPath]
            observed.setValue(FieldType.convert(value: newValue), key: property.name)
        }
    }
    
    public var projectedValue: Attribute<O, FieldType> {
        self
    }
        
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
    
    public convenience init(wrappedValue: PropertyValue, _ name: String) {
        self.init(wrappedValue: wrappedValue, name, options: [])
    }
    
    public init(wrappedValue: PropertyValue, _ name: String, options: PropertyConfiguration) {
        self.name = name
        self.defaultValue = wrappedValue
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
