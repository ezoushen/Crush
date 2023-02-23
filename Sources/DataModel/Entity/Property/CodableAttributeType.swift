//
//  CodableAttributeType.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

public protocol CodableAttributeType: AttributeType, PredicateEquatable, Codable, Hashable {
    associatedtype ManagedValue = Data?

    var data: Data { get set }

    static var encoder: JSONEncoder { get }
    static var decoder: JSONDecoder { get }
}

extension CodableAttributeType {
    @inlinable
    public static func convert(managedValue: Data?) -> Self? {
        guard let value = managedValue else { return nil }
        return try! Self.decoder.decode(Self.self, from: value)
    }

    @inlinable
    public static func convert(runtimeValue: Self?) -> Data? {
        guard let value = runtimeValue else { return nil }
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
