//
//  SearchString.swift
//  Crush
//
//  Created by ezou on 2020/3/12.
//

import Foundation

public struct SearchString {
    enum Category {
        case caseInsensitive, diacriticInsensitive, caseDiacriticInsensitive, plain
        
        var modifier: String {
            switch self {
            case .plain: return ""
            case .caseDiacriticInsensitive: return "[cd]"
            case .caseInsensitive: return "[c]"
            case .diacriticInsensitive: return "[d]"
            }
        }
    }
    
    let type: Category
    let string: String
}

extension SearchString: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self.string = value
        self.type = .plain
    }
}

public func CASE_INSENSITIVE(_ string: String) -> SearchString {
    return .init(type: .caseInsensitive, string: string)
}

public func DIACRITIC_INSENSITIVE(_ string: String) -> SearchString {
    return .init(type: .diacriticInsensitive, string: string)
}

public func CASE_DIACRITIC_INSENSITIVE(_ string: String) -> SearchString {
    return .init(type: .caseDiacriticInsensitive, string: string)
}
