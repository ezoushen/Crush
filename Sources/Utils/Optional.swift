//
//  Optional.swift
//  Crush
//
//  Created by ezou on 2020/4/18.
//

import Foundation

protocol OptionalProtocol {
    var isNil: Bool { get }
}

extension Swift.Optional: OptionalProtocol {
    var isNil: Bool {
        switch self {
        case .some(let value):
            return (value as? OptionalProtocol)?.isNil == true
        default: return true
        }
    }
}
