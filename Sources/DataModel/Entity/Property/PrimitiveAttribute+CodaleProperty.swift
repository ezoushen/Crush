//
//  PrimitiveAttribute+CodaleProperty.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

public protocol CodableProperty: FieldAttribute, PredicateEquatable, Codable, Hashable {
    associatedtype ManagedObjectValue = Data?

    var data: Data { get set }

    static var encoder: JSONEncoder { get }
    static var decoder: JSONDecoder { get }
}

extension CodableProperty {
    @inline(__always)
    public static func convert(value: Data?) -> Self? {
        guard let value = value else { return nil }
        return try! Self.decoder.decode(Self.self, from: value)
    }

    @inline(__always)
    public static func convert(value: Self?) -> Data? {
        guard let value = value else { return nil }
        return try! Self.encoder.encode(value)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
    }

    public static var encoder: JSONEncoder { JSONEncoder() }
    public static var decoder: JSONDecoder { JSONDecoder() }
    public static var nativeType: NSAttributeType { .binaryDataAttributeType }

    public var predicateValue: NSObject { data as NSData }
    public var data: Data {
        get {
            try! Self.encoder.encode(self)
        }
        mutating set {
            self = try! Self.decoder.decode(Self.self, from: newValue)
        }
    }
}
