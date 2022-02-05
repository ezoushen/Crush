//
//  SearchString.swift
//  Crush
//
//  Created by ezou on 2020/3/12.
//

import Foundation

public struct SearchString: Equatable {
    public enum Category {
        case caseInsensitive, diacriticInsensitive, caseDiacriticInsensitive, plain
        
        public var modifier: String {
            switch self {
            case .plain: return ""
            case .caseDiacriticInsensitive: return "[cd]"
            case .caseInsensitive: return "[c]"
            case .diacriticInsensitive: return "[d]"
            }
        }
    }
    
    public let type: Category
    public let string: String
}

extension SearchString: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self.string = value
        self.type = .plain
    }
    
    public init(_ value: String) {
        self.string = value
        self.type = .plain
    }
}

public extension SearchString {
    static func caseInsensitive(_ string: String) -> SearchString {
        SearchString(type: .caseInsensitive, string: string)
    }

    static func diacriticInsensitive(_ string: String) -> SearchString {
        SearchString(type: .diacriticInsensitive, string: string)
    }

    static func caseDiacriticInsensitive(_ string: String) -> SearchString {
        SearchString(type: .caseDiacriticInsensitive, string: string)
    }
}
