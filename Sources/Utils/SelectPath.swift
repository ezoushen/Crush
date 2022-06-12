//
//  CoreData.swift
//  
//
//  Created by EZOU on 2022/6/11.
//

import CoreData

public final class SelectPath<Entity: Crush.Entity>: Expressible, ExpressibleByStringLiteral {

    private(set)
    public var name: String
    public let path: String

    lazy var expression: NSExpressionDescription = {
        let desc = NSExpressionDescription()
        desc.name = name
        desc.expressionResultType = resolveResultType(from: path)
        desc.expression = NSExpression(forKeyPath: path)
        return desc
    }()

    public init(stringLiteral value: StringLiteralType) {
        name = value
        path = value
    }

    public init(_ keyPath: PartialKeyPath<Entity> & Expressible, as asName: String? = nil) {
        path = keyPath.optionalPropertyName!
        name = asName ?? path
    }

    public init(_ keyPath: String, as asName: String? = nil) {
        name = asName ?? keyPath
        path = keyPath
    }

    public func getHashValue() -> Int {
        expression.hashValue
    }

    public func asExpression() -> Any {
        expression
    }

    public func `as`(name: String) -> Self {
        self.name = name
        return self
    }

    private func resolveResultType(from path: String) -> NSAttributeType {
        var desc = Entity.Managed.entity()

        for component in path.split(separator: ".") {
            let property = desc.propertiesByName[String(component)]

            switch property {
            case let attribute as NSAttributeDescription:
                return attribute.attributeType
            case let relation as NSRelationshipDescription:
                desc = relation.destinationEntity!
                continue
            default:
                break
            }
        }

        return .undefinedAttributeType
    }
}
