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

public protocol Entity: RuntimeObject {
    static func createEntityMapping(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel) throws -> NSEntityMapping?
    static func setOverrideCacheKey(for type: Entity.Type, key: String)
    static var isAbstract: Bool { get }
    static var renamingIdentifier: String? { get }
    static var entityCacheKey: String { get }
    
    init(proxy: PropertyProxy)
    var proxy: PropertyProxy! { get }
}

public typealias HashableEntity = Hashable & Entity

extension RuntimeObject {
    static var fetchKey: String {
        return String(describing: Self.self)
    }
        
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: fetchKey)
        return request
    }
}

extension Entity {
    init(_ runtimeObject: Self, proxyType: PropertyProxyType) {
        self.init(proxy: proxyType.proxy(proxy: runtimeObject.proxy as! ConcretePropertyProxy))
    }
    
    init(_ object: NSManagedObject, proxyType: PropertyProxyType) {
        self.init(proxy: proxyType.proxy(object: object))
    }
    
    init(objectID: NSManagedObjectID, in context: NSManagedObjectContext, proxyType: PropertyProxyType) {
        self.init(proxy: proxyType.proxy(object: context.object(with: objectID)))
    }
    
    init(context: NSManagedObjectContext, proxyType: PropertyProxyType) {
        let managedObject = ManagedObject(entity: Self.entity(), insertInto: context)
        self.init(proxy: proxyType.proxy(object: managedObject))
    }
    
    internal static func dummy() -> Self {
        let key = Self.entityCacheKey
        if let object: Self = (_Shared.dummyObjects[key] as? Self) {
            return object
        }
        let runtimeObject = Self.init(proxy: DummyPropertyProxy())
        _Shared.dummyObjects[key] = runtimeObject
        return runtimeObject
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
    
    public var rawObject: NSManagedObject {
        (proxy as! ConcretePropertyProxy).rawObject
    }
    
    fileprivate func createPropertyCacheKey(domain: String, name: String) -> String {
        "\(domain).\(name)"
    }
}

open class NeutralEntityObject: NSObject, Entity, ManagedObjectProtocol {
    public static var renamingIdentifier: String? { renamingClass?.fetchKey }
    public class var renamingClass: Entity.Type? { nil }

    public class var isAbstract: Bool {
        assertionFailure("Should not call isAbstract variale directly")
        return false
    }
        
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
        description.managedObjectClassName = "Crush.ManagedObject"
        let object = Self.init(proxy: DummyPropertyProxy())
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
    
    func createProperties() -> [NSPropertyDescription] {
        let coordinator = CacheCoordinator.shared

        return _allMirrors
            .compactMap { pair, key -> NSPropertyDescription? in
                let (_label, value) = pair
                guard key == Self.entityCacheKey, let property = value as? PropertyProtocol, let label = _label else {
                    return nil
                }
                let defaultKey = createPropertyCacheKey(domain: key, name: label)
                if let description = coordinator.get(defaultKey, in: CacheType.property) {
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
                
                coordinator.set(defaultKey, value: description, in: CacheType.property)
                return description
            }
    }
    
    public var proxy: PropertyProxy!
    
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
        super.init()
        setProxy()
            
        let managedObject = (self.proxy as? ConcretePropertyProxy)?.rawObject as? ManagedObject
        managedObject?.delegates.add(self)
        guard managedObject?.isInserted == true else { return }
        managedObject?.awakeFromInsert()
    }
    
    private func setProxy() {
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
}

open class AbstractEntityObject: NeutralEntityObject {
    public override class var isAbstract: Bool {
        return superclass() == AbstractEntityObject.self
    }
}

open class EntityObject: NeutralEntityObject {
    public override class var isAbstract: Bool {
        return false
    }
}

extension NSManagedObject: RuntimeObject {
    public convenience init(context: Transaction.ReadWriteContext) {
        precondition(context is _ReadWriteTransactionContext)
        if let transactionContext = context as? _ReadWriteTransactionContext {
            self.init(context: transactionContext.context)
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

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
extension NeutralEntityObject: ObservableObject { }

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
extension Entity where Self: NeutralEntityObject {
    public func observe<T: NullableProperty & ObservableObject>(_ keyPath: KeyPath<Self, T>) -> AnyPublisher<T.PropertyValue, Never>{
        let property = self[keyPath: keyPath]
        return property.objectWillChange.map{ _ in property.wrappedValue }.eraseToAnyPublisher()
    }
}
#endif
