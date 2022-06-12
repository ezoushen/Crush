//
//  Expressible.swift
//  
//
//  Created by EZOU on 2022/6/12.
//

import Foundation

public protocol Expressible {
    func asExpression() -> Any
    func getHashValue() -> Int
}

extension Expressible {
    func equal(to: Expressible) -> Bool {
        getHashValue() == to.getHashValue()
    }
}

public struct StringExpressible: Expressible, ExpressibleByStringLiteral {
    let path: String

    public init(stringLiteral value: StringLiteralType) {
        path = String(value)
    }

    public func getHashValue() -> Int {
        path.hashValue
    }

    public func asExpression() -> Any {
        path
    }
}
