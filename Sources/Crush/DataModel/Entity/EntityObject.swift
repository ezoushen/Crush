//
//  RuntimeObject.swift
//  Crush
//
//  Created by ezou on 2019/9/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

fileprivate enum _Shared {
    @ThreadSafe
    static var dummyObjects: [String: RuntimeObject] = [:]
    
    @ThreadSafe
    static var overrideCacheKeyDict: [String: String] = [:]
}

public protocol RuntimeObject: AnyObject {
    static func entity() -> NSEntityDescription
    var rawObject: NSManagedObject { get }
}

public protocol Entity: RuntimeObject, Field {
    static func createEntityMapping(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel) throws -> NSEntityMapping?
    static func setOverrideCacheKey(for type: Entity.Type, key: String)
    static var isAbstract: Bool { get }
    static var renamingIdentifier: String? { get }
    static var entityCacheKey: String { get }
    
    init(proxy: PropertyProxy)
}

public typealias HashableEntity = Hashable & Entity

extension RuntimeObject {
    static var fetchKey: String {
        String(describing: Self.self)
    }
        
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        NSFetchRequest<NSFetchRequestResult>(entityName: fetchKey)
    }
}

extension Entity {
    init(_ object: NSManagedObject) {
        self.init(proxy: ReadWritePropertyProxy(rawObject: object))
    }
    
    init(objectID: NSManagedObjectID, in context: NSManagedObjectContext) {
        self.init(proxy: ReadWritePropertyProxy(rawObject: context.object(with: objectID)))
    }
    
    init(context: NSManagedObjectContext) {
        let managedObject = ManagedObject(entity: Self.entity(), insertInto: context)
        self.init(proxy: ReadWritePropertyProxy(rawObject: managedObject))
    }
    
    internal static func dummy() -> Self {
        let key = Self.entityCacheKey
        return _Shared.dummyObjects[key] as? Self ?? {
            let dummyObject = Self.init(proxy: ReadWritePropertyProxy.dummy())
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
}

public func == (lhs: NeutralEntityObject, rhs: NeutralEntityObject) -> Bool {
    lhs.rawObject == rhs.rawObject
}

open class NeutralEntityObject: Hashable, Entity, ManagedObjectDelegate {

    public class var isAbstract: Bool {
        return false
    }
    
    public class var renamingClass: Entity.Type? {
        return nil
    }
    
    public class var renamingIdentifier: String? {
        renamingClass?.fetchKey
    }
        
    public var rawObject: NSManagedObject {
        proxy.rawObject
    }
        
    public func hash(into hasher: inout Hasher) {
        rawObject.hash(into: &hasher)
    }
    
    public var hashValue: Int {
        rawObject.hashValue
    }
    
    private let proxy: PropertyProxy
    
    private lazy var _allMirrors: [(Mirror.Child, String)] = {
        func findAllMirrors(_ mirror: Mirror?) -> [(Mirror, String)] {
            guard let mirror = mirror else { return [] }
            
            if mirror.subjectType == EntityObject.self || mirror.subjectType == AbstractEntityObject.self {
                return []
            }
            
            guard let subjectType = mirror.subjectType as? Entity.Type else { return [] }
            return [(mirror, subjectType.entityCacheKey)] + findAllMirrors(mirror.superclassMirror)
        }
        
        return findAllMirrors(Mirror(reflecting: self)).flatMap{
            zip($0.0.children, repeatElement($0.1, count: $0.0.children.count))
        }
    }()
    
    required public init(proxy: PropertyProxy) {
        self.proxy = proxy
        
        injectProxy()
    }
        
    private func injectProxy() {
        _allMirrors
            .forEach { pair, key in
                let (label, value) = pair
                guard let property = value as? PropertyProtocol else  { return }
                property.proxy = proxy
                property.entityObject = self
                property.defaultName = String(label?.dropFirst() ?? "")
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
                description.versionHashModifier = description.name
                
                if let mapping = description.userInfo?[UserInfoKey.propertyMappingKeyPath] as? RootTracableKeyPathProtocol {
                    if mapping.fullPath.contains(".") {
                        description.userInfo?[UserInfoKey.propertyMappingSource] = mapping.fullPath
                        description.userInfo?[UserInfoKey.propertyMappingDestination] = description.name
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
    
    open dynamic func willAccessValue(forKey key: String?) { }
    
    open dynamic func didAccessValue(forKey key: String?) { }
    
    open dynamic func awakeFromFetch() { }
    
    open dynamic func awakeFromInsert() { }
    
    open dynamic func awake(fromSnapshotEvents flags: NSSnapshotEventType) { }
    
    open dynamic func prepareForDeletion() { }
    
    open dynamic func willSave() { }
    
    open dynamic func didSave() { }
    
    open dynamic func willTurnIntoFault() { }
    
    open dynamic func didTurnIntoFault() { }
    
    open dynamic func willChangeValue(forKey key: String) { }
    
    open dynamic func didChangeValue(forKey key: String) { }
    
    open dynamic func willChangeValue(forKey inKey: String,
                                      withSetMutation inMutationKind: NSKeyValueSetMutationKind,
                                      using inObjects: Set<AnyHashable>) { }
    
    open dynamic func didChangeValue(forKey inKey: String,
                                     withSetMutation inMutationKind: NSKeyValueSetMutationKind,
                                     using inObjects: Set<AnyHashable>) { }
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
    public class func createEntityMapping(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel) throws -> NSEntityMapping? {
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
    
    public class func entity() -> NSEntityDescription {
        let coordinator = CacheCoordinator.shared
        let entityKey = Self.entityCacheKey

        if let description = coordinator.get(entityKey, in: CacheType.entity) {
            return description
        }
        
        let description = NSEntityDescription()
        description.managedObjectClassName = String(reflecting: ManagedObject.self)
        let object = Self.init(proxy: ReadWritePropertyProxy.dummy())
        let mirror = Mirror(reflecting: object)
        
        // Setup properties
        let properties: [NSPropertyDescription] = object.createProperties()
        
        // Setup related inverse relationship
        coordinator.getAndWait(entityKey, in: CacheType.inverseRelationship) { pairs in
            pairs.forEach { (keyPath, relationship) in
                if let prop = object[keyPath: keyPath] as? PropertyProtocol,
                    let description = prop.description as? NSRelationshipDescription {
                    relationship.inverseRelationship = description
                    
                    if let flag = relationship.userInfo?[UserInfoKey.inverseUnidirectional] as? Bool, flag { return }
                    
                    description.inverseRelationship = relationship
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
        
        // Setup Constraints
        if let constraintClass = NSClassFromString((NSStringFromClass(Self.self)+"10Constraint").replacingOccurrences(of: "_TtC", with: "_TtCC")) as? ConstraintSet.Type {
            constraintClass.setDefaultKeys(mirror: mirror)
            let indexClassMirror = Mirror(reflecting: constraintClass.init())
            let indexChildren = indexClassMirror.children
            let indexes: [NSFetchIndexDescription] = indexChildren.compactMap{ (label, value) in
                guard let index = value as? IndexProtocol else { return nil }
                return index.fetchIndexDescription(name: label ?? "", in: object)
            }
            let uniquenessConstarints: [[Any]] = Set<[String]>(
                indexChildren.compactMap { (label, value) -> [String]? in
                    guard let constraint = value as? UniqueConstraintProtocol else{ return nil }
                    return constraint.uniquenessConstarints
                }
            ).map{ $0 as [Any]}
            description.indexes = indexes
            description.uniquenessConstraints = uniquenessConstarints
        }
        
        return description
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
extension NeutralEntityObject: ObservableObject { }


@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
extension Entity where Self: NeutralEntityObject {
    public func observe<T: NullableProperty & ObservableObject>(_ keyPath: KeyPath<Self, T>, containsCurrent: Bool = false) -> AnyPublisher<T.PropertyValue, Never>{
        let property = self[keyPath: keyPath]
        guard containsCurrent else {
            return property.objectWillChange.map{ _ in property.wrappedValue }.eraseToAnyPublisher()
        }
        return property.objectWillChange.map{ _ in property.wrappedValue }.append(property.wrappedValue).eraseToAnyPublisher()
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
extension Publisher where Self.Failure == Never {
    public func assign<Root: HashableEntity>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, on object: Editable<Root>) -> AnyCancellable {
        self.sink {
            object[dynamicMember: keyPath] = $0
        }
    }
}
#endif
