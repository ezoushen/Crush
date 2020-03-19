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
        let managedObject = NSManagedObject(entity: Self.entity(), insertInto: context)
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

open class NeutralEntityObject: NSObject, Entity {
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
        let coordinator = DescriptionCacheCoordinator.shared
        let entityKey = Self.entityCacheKey

        if let description = coordinator.getDescription(entityKey, type: EntityCacheType.self) {
            return description
        }
        
        let description = NSEntityDescription()
        let object = Self.init(proxy: DummyPropertyProxy())
        let mirror = Mirror(reflecting: object)
        
        // Setup properties
        let properties: [NSPropertyDescription] = object.createProperties()
        
        // Setup related inverse relationship
        coordinator.getAndWaitDescription(entityKey, type: InverRelationshipCacheType.self) { pairs in
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
        coordinator.setDescription(entityKey, value: description, type: EntityCacheType.self)
        description.relationshipsByName.forEach { name, relationship in
            guard let destinationKey = relationship.userInfo?[UserInfoKey.relationshipDestination] as? String else { return }
            
            if let inverseKey = relationship.userInfo?[UserInfoKey.inverseRelationship] as? AnyKeyPath,
                let inverseType = relationship.userInfo?[UserInfoKey.relationshipDestination] as? String {
                let arr = coordinator.getDescription(inverseType, type: InverRelationshipCacheType.self) ?? []
                coordinator.setDescription(inverseType, value: arr + [(inverseKey, relationship)], type: InverRelationshipCacheType.self)
            }
            
            coordinator.getAndWaitDescription(destinationKey, type: EntityCacheType.self) {
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
            coordinator.getAndWaitDescription(superType.entityCacheKey, type: EntityCacheType.self) {
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
    
    func createProperties() -> [NSPropertyDescription] {
        let coordinator = DescriptionCacheCoordinator.shared

        return _allMirrors
            .compactMap { pair, key -> NSPropertyDescription? in
                let (_label, value) = pair
                guard key == Self.entityCacheKey, let property = value as? PropertyProtocol, let label = _label else {
                    return nil
                }
                let defaultKey = createPropertyCacheKey(domain: key, name: label)
                if let description = coordinator.getDescription(defaultKey, type: PropertyCacheType.self) {
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
                
                coordinator.setDescription(defaultKey, value: description, type: PropertyCacheType.self)
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
    }
    
    private func setProxy() {
        _allMirrors
            .forEach { pair, key in
                let (label, value) = pair
                guard var property = value as? PropertyProtocol else  { return }
                property.proxy = proxy
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
