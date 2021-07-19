//
//  RuntimeObject.swift
//  Crush
//
//  Created by ezou on 2019/9/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public protocol Entity: NSObject, Field {
    static func entityDescription() -> NSEntityDescription
    static var isAbstract: Bool { get }
    static var renamingIdentifier: String? { get }
    static var entityCacheKey: String { get }

    init()
    func createProperties() -> [NSPropertyDescription]
}

extension Entity {
    public static var entityCacheKey: String {
        String(reflecting: Self.self)
    }
    
    static var fetchKey: String {
        String(describing: Self.self)
    }
        
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        NSFetchRequest<NSFetchRequestResult>(entityName: fetchKey)
    }
    
    static func createPropertyCacheKey(domain: String = entityCacheKey, name: String) -> String {
        "\(domain).\(name)"
    }
    
    public static func entityDescription() -> NSEntityDescription {
        let coordinator = CacheCoordinator.shared
        let entityKey = Self.entityCacheKey

        if let description = coordinator.get(entityKey, in: CacheType.entity) {
            return description
        }
        
        let description = NSEntityDescription()
        description.managedObjectClassName = NSStringFromClass(ManagedObject<Self>.self)
        
        let object = Self.init()
        let mirror = Mirror(reflecting: object)
        
        // Setup properties
        let properties: [NSPropertyDescription] = object.createProperties()
        
        // Setup related inverse relationship
        coordinator.getAndWait(entityKey, in: CacheType.inverseRelationship) { pairs in
            pairs.forEach { (keyPath, relationship) in
                if let prop = object[keyPath: keyPath] as? PropertyProtocol {
                    let key = Self.createPropertyCacheKey(domain: entityKey, name: prop.name)
                    if let description = coordinator.get(key, in: CacheType.property) as? NSRelationshipDescription {
                        relationship.inverseRelationship = description
                        
                        if let flag = relationship.userInfo?[UserInfoKey.inverseUnidirectional] as? Bool, flag { return }
                        
                        description.inverseRelationship = relationship
                    }
                }
            }
        }
        
        description.name = fetchKey
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
            superMirror.subjectType != EntityObject.self,
            let superType = superMirror.subjectType as? Entity.Type {
            coordinator.getAndWait(superType.entityCacheKey, in: CacheType.entity) { entity in
                entity.subentities.append(description)
                
                func registerAllProperties(description: NSEntityDescription) {
                    description.propertiesByName.forEach {
                        coordinator.set(createPropertyCacheKey(name: $0.value.name), value: $0.value, in: CacheType.property)
                    }
                    
                    guard let superentity = description.superentity else {
                        return
                    }
                    
                    registerAllProperties(description: superentity)
                }
                
                registerAllProperties(description: entity)
            }
        }
        
        return description
    }
    
    static func createConstraints(description: NSEntityDescription) {
        let object = Self.init()
        let mirror = Mirror(reflecting: object)
        
        func createIndexClassFromMirror(_ mirror: Mirror) -> ConstraintSet.Type? {
            NSClassFromString((NSStringFromClass(mirror.subjectType.self as! AnyClass)+"10Constraint").replacingOccurrences(of: "_TtC", with: "_TtCC")) as? ConstraintSet.Type
        }

        var allIndexes: [NSFetchIndexDescription] = []
        var allUniquenessConstraints: [[Any]] = []
        
        func resolveIndexes(objectMirror mirror: Mirror?, constraintClass: ConstraintSet.Type?) {
            guard let mirror = mirror,
                  let constraintClass = constraintClass ?? createIndexClassFromMirror(mirror),
                      mirror.subjectType == Self.self
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
                    let description = CacheCoordinator.shared.get(Self.createPropertyCacheKey(name: value.anyKeyPath.stringValue), in: CacheType.property)
                else { return }
                
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
                resolveIndexes(objectMirror: mirror, constraintClass: constraintClass)
            } else {
                traverseConstraints(from: rootMirror, atMirror: mirror.superclassMirror)
            }
        }
        
        traverseConstraints(from: mirror, atMirror: mirror)

        description.indexes.append(contentsOf: allIndexes)
        description.uniquenessConstraints.append(contentsOf: allUniquenessConstraints)
    }
    
    static func createEntityMapping(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel) throws -> NSEntityMapping? {
        var fromEntityTypeName: String? = nil
        var toEntityTypeName: String? = nil
        
        let attributeMappings = try entityDescription().properties
            .filter { $0 is NSAttributeDescription }
            .compactMap { property -> PropertyMappingProtocol? in
            guard let fromEntityType = property.userInfo?[UserInfoKey.propertyMappingRoot] as? Entity.Type,
                  let toEntityType = property.userInfo?[UserInfoKey.propertyMappingValue] as? Entity.Type,
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
            guard let fromEntityType = property.userInfo?[UserInfoKey.propertyMappingRoot] as? Entity.Type,
                  let toEntityType = property.userInfo?[UserInfoKey.propertyMappingValue] as? Entity.Type,
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

open class EntityObject: NSObject, Entity {
    public class var isAbstract: Bool {
        return false
    }
    
    public class var renamingClass: Entity.Type? {
        return nil
    }
    
    public class var renamingIdentifier: String? {
        renamingClass?.fetchKey
    }

    public override required init() {
        super.init()
    }
    
    private lazy var _allMirrors: [(Mirror.Child, String)] = {
        func findAllMirrors(_ mirror: Mirror?) -> [(Mirror, String)] {
            guard let mirror = mirror else { return [] }
            
            if mirror.subjectType == EntityObject.self {
                return []
            }
            
            guard let subjectType = mirror.subjectType as? Entity.Type,
                let superClassMirror = mirror.superclassMirror else { return [] }
            
            return [(mirror, subjectType.entityCacheKey)] + findAllMirrors(superClassMirror)
        }
        
        return findAllMirrors(Mirror(reflecting: self)).flatMap{
            zip($0.0.children, repeatElement($0.1, count: $0.0.children.count))
        }
    }()
    
    public func createProperties() -> [NSPropertyDescription] {
        _allMirrors
            .compactMap { pair, key -> NSPropertyDescription? in
                let (_, value) = pair
                guard key == Self.entityCacheKey,
                    let property = value as? PropertyProtocol  else {
                    return nil
                }
                let defaultKey = Self.createPropertyCacheKey(domain: key, name: property.name)
                if let description = CacheCoordinator.shared.get(defaultKey, in: CacheType.property) {
                    return description
                }
                let description = property.emptyPropertyDescription()
                
                if let mapping = description.userInfo?[UserInfoKey.propertyMappingKeyPath] as? RootTracableKeyPathProtocol {
                    if mapping.stringValue.contains(".") {
                        description.userInfo?[UserInfoKey.propertyMappingSource] = mapping.stringValue
                        description.userInfo?[UserInfoKey.propertyMappingDestination] = property.name
                        description.userInfo?[UserInfoKey.propertyMappingRoot] = mapping.rootType
                        description.userInfo?[UserInfoKey.propertyMappingValue] = type(of: self)
                    } else {
                        description.renamingIdentifier = mapping.stringValue
                    }
                }
                
                CacheCoordinator.shared.set(defaultKey, value: description, in: CacheType.property)
                return description
            }
    }
}
