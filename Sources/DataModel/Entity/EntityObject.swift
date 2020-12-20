//
//  RuntimeObject.swift
//  Crush
//
//  Created by ezou on 2019/9/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

let kEntityTypeKey: String = "entity.type"

fileprivate enum _Shared {
    @ThreadSafe
    static var dummyObjects: [String: RuntimeObject] = [:]
    
    @ThreadSafe
    static var overrideCacheKeyDict: [String: String] = [:]
}

public protocol RuntimeObject: AnyObject {
    static func entity() -> NSEntityDescription
    static func createConstraints(description: NSEntityDescription)
    var rawObject: NSManagedObject { get }
}

extension RuntimeObject {
    public static func createConstraints(description: NSEntityDescription) { }
}

public protocol Entity: RuntimeObject, Field {
    static func setOverrideCacheKey(for type: Entity.Type, key: String)
    static var isAbstract: Bool { get }
    static var renamingIdentifier: String? { get }
    static var entityCacheKey: String { get }
    
    init()
    init(context: NSManagedObjectContext)
}

public protocol HashableEntity: NSManagedObject ,Entity {
    var contentHashValue: Int { get }
}

extension RuntimeObject {
    static var fetchKey: String {
        String(describing: Self.self)
    }
        
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        NSFetchRequest<NSFetchRequestResult>(entityName: fetchKey)
    }
}

extension Entity {
    internal static func dummy() -> Self {
        let key = Self.entityCacheKey
        return _Shared.dummyObjects[key] as? Self ?? {
            let dummyObject = Self.init()
            (dummyObject as? NeutralEntityObject)?.insertDefautCacheKey()
            _Shared.dummyObjects[key] = dummyObject
            return dummyObject
        }()
    }
    
    public static func setOverrideCacheKey(for type: Entity.Type, key: String) {
        _Shared.overrideCacheKeyDict[type.defaultCacheKey] = key
    }

    public static var entityCacheKey: String {
        _Shared.overrideCacheKeyDict[defaultCacheKey] ?? defaultCacheKey
    }
    
    static var defaultCacheKey: String {
        String(reflecting: Self.self)
    }
    
    fileprivate func createPropertyCacheKey(domain: String, name: String) -> String {
        "\(domain).\(name)"
    }
    
    static func createEntityMapping(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel) throws -> NSEntityMapping? {
        var fromEntityTypeName: String? = nil
        var toEntityTypeName: String? = nil
        
        let attributeMappings = try entity().properties
            .filter { $0 is NSAttributeDescription }
            .compactMap { property -> PropertyMappingProtocol? in
            guard let fromEntityType = property.userInfo?[UserInfoKey.propertyMappingRoot] as? RuntimeObject.Type,
                  let toEntityType = property.userInfo?[UserInfoKey.propertyMappingValue] as? RuntimeObject.Type,
                  let fromPath = property.userInfo?[UserInfoKey.propertyMappingSource] as? String,
                  let toPath = property.userInfo?[UserInfoKey.propertyMappingDestination] as? String
                else { return nil }
                
                if (fromEntityTypeName == nil && toEntityTypeName == nil ) {
                    fromEntityTypeName = fromEntityType.fetchKey
                    toEntityTypeName = toEntityType.fetchKey
                } else if fromEntityTypeName != fromEntityType.fetchKey || toEntityTypeName != toEntityType.fetchKey {
                    throw EntityMappingError.entityTypeMismatch
                }
            return AnyPropertyMapping(type: .attribute, from: fromPath, to: toPath)
        }
        
        let relationshipMappings = try entity().properties
            .filter { $0 is NSRelationshipDescription }
            .compactMap { property -> PropertyMappingProtocol? in
            guard let fromEntityType = property.userInfo?[UserInfoKey.propertyMappingRoot] as? RuntimeObject.Type,
                  let toEntityType = property.userInfo?[UserInfoKey.propertyMappingValue] as? RuntimeObject.Type,
                  let fromPath = property.userInfo?[UserInfoKey.propertyMappingSource] as? String,
                  let toPath = property.userInfo?[UserInfoKey.propertyMappingDestination] as? String
                else { return nil }
                
                if (fromEntityTypeName == nil && toEntityTypeName == nil ) {
                    fromEntityTypeName = fromEntityType.fetchKey
                    toEntityTypeName = toEntityType.fetchKey
                } else if fromEntityTypeName != fromEntityType.fetchKey || toEntityTypeName != toEntityType.fetchKey {
                    throw EntityMappingError.entityTypeMismatch
                }
            return AnyPropertyMapping(type: .relationship, from: fromPath, to: toPath)
        }
        
        guard let sourceName = fromEntityTypeName, let destinationName = toEntityTypeName else {
            return nil
        }
                
        return try AnyEntityMapping(type: .transform,
                                    source: sourceName,
                                    destination: destinationName,
                                    attributes: attributeMappings,
                                    relations: relationshipMappings)
            .entityMapping(sourceModel: sourceModel,
                           destinationModel: destinationModel)
    }
}

open class NeutralEntityObject: NSManagedObject, HashableEntity {

    public class var isAbstract: Bool {
        return false
    }
    
    public class var renamingClass: Entity.Type? {
        return nil
    }
    
    public class var renamingIdentifier: String? {
        renamingClass?.fetchKey
    }
    
    public var contentHashValue: Int {
        let names = rawObject.entity.attributesByName.keys.map { $0 }
        return rawObject.dictionaryWithValues(forKeys: names)
            .map { $0 }
            .sorted { $0.key < $1.key }
            .description
            .hash
    }
    
    private lazy var _allMirrors: [(Mirror.Child, String)] = {
        func findAllMirrors(_ mirror: Mirror?) -> [(Mirror, String)] {
            guard let mirror = mirror else { return [] }
            
            if mirror.subjectType == EntityObject.self || mirror.subjectType == AbstractEntityObject.self {
                return []
            }
            
            guard let subjectType = mirror.subjectType as? Entity.Type,
                let superClassMirror = mirror.superclassMirror else { return [] }
            
            return [(mirror, superClassMirror.subjectType.self == AbstractEntityObject.self ? subjectType.entityCacheKey : Self.entityCacheKey)] + findAllMirrors(superClassMirror)
        }
        
        return findAllMirrors(Mirror(reflecting: self)).flatMap{
            zip($0.0.children, repeatElement($0.1, count: $0.0.children.count))
        }
    }()
    
    func insertDefautCacheKey() {
        _allMirrors
            .forEach { pair, key in
                let (label, value) = pair
                guard let property = value as? PropertyProtocol else  { return }
                property.entityObject = self
                property.propertyCacheKey = createPropertyCacheKey(domain: key, name: label!)
            }
    }
    
    func createProperties() -> [NSPropertyDescription] {
        _allMirrors
            .compactMap { pair, key -> NSPropertyDescription? in
                let (_label, value) = pair
                guard key == Self.entityCacheKey,
                    let property = value as? PropertyProtocol,
                    let label = _label else {
                    return nil
                }
                let defaultKey = createPropertyCacheKey(domain: key, name: label)
                if let description = CacheCoordinator.shared.get(defaultKey, in: CacheType.property) {
                    return description
                }
                let description = property.emptyPropertyDescription()
                
                if let mapping = description.userInfo?[UserInfoKey.propertyMappingKeyPath] as? RootTracableKeyPathProtocol {
                    if mapping.fullPath.contains(".") {
                        description.userInfo?[UserInfoKey.propertyMappingSource] = mapping.fullPath
                        description.userInfo?[UserInfoKey.propertyMappingDestination] = property.defaultName
                        description.userInfo?[UserInfoKey.propertyMappingRoot] = mapping.rootType
                        description.userInfo?[UserInfoKey.propertyMappingValue] = type(of: self)
                    } else {
                        description.renamingIdentifier = mapping.fullPath
                    }
                }
                
                CacheCoordinator.shared.set(defaultKey, value: description, in: CacheType.property)
                return description
            }
    }
}

open class AbstractEntityObject: NeutralEntityObject {
    public override class var isAbstract: Bool {
        return class_getSuperclass(Self.self) == AbstractEntityObject.self
    }
}

open class EntityObject: NeutralEntityObject {
    public override class var isAbstract: Bool {
        return false
    }
}

extension NeutralEntityObject {
    public override class func entity() -> NSEntityDescription {
        let coordinator = CacheCoordinator.shared
        let entityKey = Self.entityCacheKey

        if let description = coordinator.get(entityKey, in: CacheType.entity) {
            return description
        }
        
        let description = NSEntityDescription()
        description.managedObjectClassName = NSStringFromClass(Self.self)
        let object = Self.init()
        let mirror = Mirror(reflecting: object)
        
        // Setup properties
        let properties: [NSPropertyDescription] = object.createProperties()
        
        // Setup related inverse relationship
        coordinator.getAndWait(entityKey, in: CacheType.inverseRelationship) { pairs in
            pairs.forEach { (keyPath, relationship) in
                if let prop = object[keyPath: keyPath] as? PropertyProtocol {
                    prop.propertyCacheKey = object.createPropertyCacheKey(domain: entityKey, name: "_\(prop.defaultName)")
                    if let description = prop.description as? NSRelationshipDescription {
                        relationship.inverseRelationship = description
                        
                        if let flag = relationship.userInfo?[UserInfoKey.inverseUnidirectional] as? Bool, flag { return }
                        
                        description.inverseRelationship = relationship
                    }
                }
            }
        }
        
        description.name = String(describing: Self.self)
        description.properties = properties
        description.isAbstract = isAbstract
        description.renamingIdentifier = renamingIdentifier
        
        // Setup relationship
        coordinator.set(entityKey, value: description, in: CacheType.entity)
        description.relationshipsByName.forEach { name, relationship in
            guard let destinationKey = relationship.userInfo?[UserInfoKey.relationshipDestination] as? String else { return }
            
            if let inverseKey = relationship.userInfo?[UserInfoKey.inverseRelationship] as? AnyKeyPath,
                let inverseType = relationship.userInfo?[UserInfoKey.relationshipDestination] as? String {
                let arr = coordinator.get(inverseType, in: CacheType.inverseRelationship) ?? []
                coordinator.set(inverseType, value: arr + [(inverseKey, relationship)], in: CacheType.inverseRelationship)
            }
            
            coordinator.getAndWait(destinationKey, in: CacheType.entity) {
                relationship.destinationEntity = $0
            }
        }
        
        // Setup parent entity
        if let superMirror = mirror.superclassMirror,
            superMirror.subjectType is Entity.Type,
            superMirror.subjectType != NeutralEntityObject.self,
            superMirror.subjectType != EntityObject.self,
            superMirror.subjectType != AbstractEntityObject.self,
            let superType = superMirror.subjectType as? Entity.Type {
            coordinator.getAndWait(superType.entityCacheKey, in: CacheType.entity) {
                $0.subentities.append(description)
            }
        }
        
        description.userInfo?[kEntityTypeKey] = NSStringFromClass(Self.self)
        return description
    }
    
    public class func createConstraints(description: NSEntityDescription) {
        let object = Self.init()
        let mirror = Mirror(reflecting: object)
        
        func createIndexClassFromMirror(_ mirror: Mirror) -> ConstraintSet.Type? {
            return NSClassFromString((NSStringFromClass(mirror.subjectType.self as! AnyClass)+"10Constraint").replacingOccurrences(of: "_TtC", with: "_TtCC")) as? ConstraintSet.Type
        }

        var allIndexes: [NSFetchIndexDescription] = []
        var allUniquenessConstraints: [[Any]] = []
        
        func resolveIndexes(objectMirror mirror: Mirror?, constraintClass: ConstraintSet.Type?) {
            guard let mirror = mirror,
                  let constraintClass = constraintClass ?? createIndexClassFromMirror(mirror),
                  mirror.superclassMirror?.subjectType != AbstractEntityObject.self || mirror.subjectType == Self.self
                else { return }
            let indexClassMirror = Mirror(reflecting: constraintClass.init())
            let indexChildren = indexClassMirror.children
            let indexes: [NSFetchIndexDescription] = indexChildren.compactMap{ (label, value) in
                guard let index = value as? IndexProtocol else { return nil }
                return index.fetchIndexDescription(name: label ?? "", in: object)
            }
            
            if description.superentity != nil {
                indexes
                    .filter{ $0.elements.count > 1 }
                    .forEach {
                        let expression = NSExpressionDescription()
                        expression.expression = .init(format: "entity")
                        expression.expressionResultType = .stringAttributeType
                        expression.name = "Expression"
                        let collationType = $0.elements.first!.collationType
                        let entIndex = NSFetchIndexElementDescription(property: expression, collationType: collationType)
                        $0.elements.insert(entIndex, at: 0)
                    }
            }
            
            let uniquenessConstarints: [[Any]] = Set<[String]>(
                indexChildren.compactMap { (label, value) -> [String]? in
                    guard let constraint = value as? UniqueConstraintProtocol else{ return nil }
                    return constraint.uniquenessConstarints
                }
            ).map{ $0 as [Any]}
            
            allIndexes.append(contentsOf: indexes)
            allUniquenessConstraints.append(contentsOf: uniquenessConstarints)
            
            indexChildren.forEach { (label, value) in
                guard let value = value as? ValidationProtocol,
                    let description = (object[keyPath: value.anyKeyPath] as? PropertyProtocol)?.description else { return }
                
                var warnings = description.validationWarnings
                var predicates = description.validationPredicates
                
                warnings.append(value.wrappedValue.1)
                predicates.append(value.wrappedValue.0)
                
                description.setValidationPredicates(predicates, withValidationWarnings: warnings as? [String])
            }
            
            return resolveIndexes(objectMirror: mirror.superclassMirror, constraintClass: nil)
        }
        
        func traverseConstraints(from rootMirror: Mirror, atMirror mirror: Mirror? = nil) {
            guard let mirror = mirror else { return }
            
            if let constraintClass = createIndexClassFromMirror(mirror) {
                constraintClass.setDefaultKeys(mirror: rootMirror)
                resolveIndexes(objectMirror: mirror, constraintClass: constraintClass)
            } else {
                traverseConstraints(from: rootMirror, atMirror: mirror.superclassMirror)
            }
        }
        
        traverseConstraints(from: mirror, atMirror: mirror)

        description.indexes.append(contentsOf: allIndexes)
        description.uniquenessConstraints.append(contentsOf: allUniquenessConstraints)
    }
}

extension NSManagedObject: RuntimeObject {
    public convenience init(context: TransactionContext) {
        if let transactionContext = context as? _TransactionContext {
            self.init(context: transactionContext.executionContext)
        } else {
            fatalError()
        }
    }
    
    public var rawObject: NSManagedObject {
        self
    }
}

#if canImport(Combine)
import Combine
import SwiftUI

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
extension Publisher where Self.Failure == Never {
    public func assign<Root: HashableEntity>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, on object: Root.ReadOnly, in transaction: Transaction) -> AnyCancellable {
        sink {
            Editable(object, transaction: transaction)[dynamicMember: keyPath] = $0
        }
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
extension Publisher {
    public func tryMap<T>(transaction: Crush.Transaction, _ block: @escaping (TransactionContext, Output) throws -> T) -> Publishers.TryMap<Self, T> {
        tryMap { value in
            try transaction.sync { context in
                try block(context, value)
            }
        }
    }
    
    public func tryMap<T: HashableEntity>(transaction: Crush.Transaction, _ block: @escaping (TransactionContext, Output) throws -> T) -> Publishers.TryMap<Self, T.ReadOnly> {
        tryMap { value in
            try transaction.sync { context in
                try block(context, value)
            }
        }
    }
    
    public func tryMap<T: HashableEntity>(transaction: Crush.Transaction, _ block: @escaping (TransactionContext, Output) throws -> [T]) -> Publishers.TryMap<Self, [T.ReadOnly]> {
        tryMap { value in
            try transaction.sync { context in
                try block(context, value)
            }
        }
    }
}
#endif
