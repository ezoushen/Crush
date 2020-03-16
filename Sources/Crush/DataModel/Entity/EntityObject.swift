//
//  RuntimeObject.swift
//  Crush
//
//  Created by ezou on 2019/9/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public protocol RuntimeObject: AnyObject {
    typealias Proxy = ReadOnlyValueMapperProtocol & ValueProviderProtocol

    init()
    var proxyType: Proxy.Type { get set }
    var rawObject: NSManagedObject! { get set }
    static var isProxy: Bool { get }
    static func entity() -> NSEntityDescription
}

public protocol Entity: RuntimeObject {
    static func entityDescription() -> NSEntityDescription
    static func createEntityMapping(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel) throws -> NSEntityMapping?
    static func entity() -> NSEntityDescription
    static func setOverrideCacheKey(for type: Entity.Type, key: String)
    static var isAbstract: Bool { get }
    static var renamingIdentifier: String? { get }
    static var entityCacheKey: String { get }
    var entity: NSEntityDescription { get }
}

fileprivate enum _Shared {
    @ThreadSafe
    static var dummyObjects: [String: RuntimeObject] = [:]
    
    @ThreadSafe
    static var overrideCacheKeyDict: [String: String] = [:]
}

extension RuntimeObject {
    static var fetchKey: String {
        return String(describing: Self.self)
    }
    
    static func create(_ runtimeObject: Self, proxyType: Proxy.Type) -> Self {
        let object = Self.init()
        object.proxyType = proxyType
        object.rawObject = runtimeObject.rawObject
        return object
    }
    
    static func create(_ object: NSManagedObject, proxyType: Proxy.Type = ReadOnlyValueMapper.self) -> Self {
        let entity = Self.init()
        entity.proxyType = proxyType
        entity.rawObject = object
        return entity
    }
    
    static func create(objectID: NSManagedObjectID, in context: NSManagedObjectContext, proxyType: Proxy.Type = ReadOnlyValueMapper.self) -> Self {
        let object = Self.init()
        object.proxyType = proxyType
        object.rawObject = context.object(with: objectID)
        return object
    }
}

extension RuntimeObject where Self == NSManagedObject {
    static func create(_ object: NSManagedObject, proxyType: Proxy.Type = ReadOnlyValueMapper.self) -> NSManagedObject {
        object
    }
    
    static func create(objectID: NSManagedObjectID, in context: NSManagedObjectContext, proxyType: Proxy.Type = ReadOnlyValueMapper.self) -> NSManagedObject {
        context.object(with: objectID)
    }
}

extension Entity where Self == NSManagedObject {
    static func create(context: NSManagedObjectContext, proxyType: Proxy.Type = ReadOnlyValueMapper.self) -> NSManagedObject {
        NSManagedObject(entity: Self.dummy().entity, insertInto: context)
    }
}


extension Entity {
    static func create(context: NSManagedObjectContext, proxyType: Proxy.Type = ReadOnlyValueMapper.self) -> Self {
        let managedObject = NSManagedObject(entity: Self.dummy().entity, insertInto: context)
        let object = Self.init()
        object.proxyType = proxyType
        object.rawObject = managedObject
        return object
    }
        
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityCacheKey)
        return request
    }
    
    public static func entity() -> NSEntityDescription {
        return DescriptionCacheCoordinator.shared.getDescription(entityCacheKey, type: EntityCacheType.self) ?? entityDescription()
    }
    
    internal static func dummy() -> Self {
        let key = Self.entityCacheKey
        if let object: Self = (_Shared.dummyObjects[key] as? Self) {
            return object
        }
        let runtimeObject = Self.init()
        runtimeObject.setupProperties(mirror: Mirror(reflecting: runtimeObject), recursive: true)
        _Shared.dummyObjects[key] = runtimeObject
        return runtimeObject
    }
    
    public var entity: NSEntityDescription {
        return Self.entity()
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
    
    @discardableResult func setupProperties(mirror: Mirror?, recursive: Bool) -> [NSPropertyDescription] {
        guard let mirror = mirror, let objectType = mirror.subjectType as? Entity.Type else { return [] }
        let coordinator = DescriptionCacheCoordinator.shared
        let properties = mirror.children
        .compactMap { (label, value) -> NSPropertyDescription? in
            let defaultKey = "\(objectType.entityCacheKey).\(label!)"
            guard var property = value as? PropertyProtocol,
                  var description = property.description, let label = label else {
                    return nil
            }
            defer {
                property.description = description
            }
            
            if let _description = coordinator.getDescription(defaultKey, type: PropertyCacheType.self) {
                description = _description
                return description
            }
            
            description.name = description.name.isEmpty
                ? property.name ?? String(label.dropFirst())
                : description.name
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
            return recursive
            ? properties + setupProperties(mirror: mirror.superclassMirror, recursive: recursive)
            : properties
        
    }
}

open class NeutralEntityObject: NSObject, Entity {
    public class var isProxy: Bool { true }
    
    public static var renamingIdentifier: String? { renamingClass?.fetchKey }
    public class var renamingClass: Entity.Type? { nil}

    public class var isAbstract: Bool {
        assertionFailure("Should not call isAbstract variale directly")
        return false
    }
        
    public class func createEntityMapping(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel) throws -> NSEntityMapping? {
        var fromEntityTypeName: String? = nil
        var toEntityTypeName: String? = nil
        
        let attributeMappings = try entityDescription().properties
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
        
        let relationshipMappings = try entityDescription().properties
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
    
    public class func entityDescription() -> NSEntityDescription {
        let coordinator = DescriptionCacheCoordinator.shared
        let entityKey = Self.entityCacheKey

        if let description = coordinator.getDescription(entityKey, type: EntityCacheType.self) {
            return description
        }
        
        let description = NSEntityDescription()
        let object = Self.init()
        let mirror = Mirror(reflecting: object)
        
        // Setup properties
        let properties: [NSPropertyDescription] = object.setupProperties(mirror: mirror, recursive: false)
        
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
            let superType = superMirror.subjectType as? EntityObject.Type {
            coordinator.getAndWaitDescription(superType.entityCacheKey, type: EntityCacheType.self) {
                $0.subentities.append(description)
            }
        }
        
        // Setup Indices
        if let indexClass = NSClassFromString((NSStringFromClass(Self.self)+"5Index").replacingOccurrences(of: "_TtC", with: "_TtCC")) as? IndexSetProtocol.Type {
            indexClass.setDefaultKeys(mirror: mirror)
            let indexClassMirror = Mirror(reflecting: indexClass.init())
            let indexes: [NSFetchIndexDescription] = indexClassMirror.children.compactMap{ (label, value) in
                guard let index = value as? IndexProtocol else { return nil }
                return index.fetchIndexDescription(name: label ?? "", in: object)
            }
            description.indexes = indexes
        }
        
        return description
    }
    
    final public var rawObject: NSManagedObject! = nil {
        didSet {
            setProxy()
        }
    }
    
    public var proxyType: Proxy.Type = ReadWriteValueMapper.self
    
    private lazy var _allMirrors: [(Mirror.Child, String)] = {
        func findAllMirrors(_ mirror: Mirror?) -> [(Mirror, String)] {
            guard let mirror = mirror else { return [] }
            
            if mirror.subjectType == EntityObject.self || mirror.subjectType == AbstractEntityObject.self {
                return []
            }
            
            guard let subjectType = mirror.subjectType as? EntityObject.Type else { return [] }
            
            return [(mirror, String(reflecting: subjectType))] + findAllMirrors(mirror.superclassMirror)
        }
        
        return findAllMirrors(Mirror(reflecting: self)).flatMap{
            zip($0.0.children, repeatElement($0.1, count: $0.0.children.count))
        }
    }()
    
    
    required override public init() {
        super.init()
    }
    
    private func setProxy() {
        _allMirrors
            .forEach { pair, key in
                let (label, value) = pair
                guard var property = value as? PropertyProtocol else  { return }
                let object = proxyType.init(rawObject: rawObject)
                DescriptionCacheCoordinator.shared.getAndWaitDescription(key + ".\(label!)",
                                                                         type: PropertyCacheType.self) { element in
                    property.description = element
                    property.valueMappingProxy = object
                }
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

extension NSManagedObject: Entity {
    public class var isProxy: Bool {
        false
    }
    
    public static var entityCacheKey: String {
        defaultCacheKey
    }
        
    public convenience init(context: Transaction.ReadWriteContext) {
        precondition(context is _ReadWriteTransactionContext)
        if let transactionContext = context as? _ReadWriteTransactionContext {
            self.init(context: transactionContext.context)
        } else if let transactionContext = context as? _ReadWriteTransactionContext {
            self.init(context: transactionContext.context)
        }
        fatalError()
    }
    
    public static var renamingIdentifier: String? {
        return entity().renamingIdentifier
    }
    
    public static func createEntityMapping(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel) throws -> NSEntityMapping? {
        nil
    }
    
    public static var isAbstract: Bool {
        return entity().isAbstract
    }
        
    public static func entityDescription() -> NSEntityDescription {
        return Self.entity()
    }
    
    public var proxyType: Proxy.Type {
        get {
            ReadWriteValueMapper.self
        }
        set {
            assertionFailure("Should not set this property directly")
        }
    }
    
    public var rawObject: NSManagedObject! {
        get {
            return self
        }
        set {
            assertionFailure("Should not set this property directly")
        }
    }
}
