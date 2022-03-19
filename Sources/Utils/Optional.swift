//
//  Optional.swift
//  Crush
//
//  Created by ezou on 2020/4/18.
//

import Foundation

public protocol OptionalProtocol {
    var isNil: Bool { get }
    static var null: Self { get }
}

extension Swift.Optional: OptionalProtocol {
    @inlinable
    public var isNil: Bool {
        switch self {
        case .some(let value):
            return (value as? OptionalProtocol)?.isNil == true
        default: return true
        }
    }

    @inlinable
    public static var null: Self {
        return .none
    }
}

extension Swift.Optional {
    @inlinable var contentDescription: String {
        switch self {
        case .none: return "null"
        case .some(let value): return "\(value)"
        }
    }
}
