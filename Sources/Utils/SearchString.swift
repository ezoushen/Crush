//
//  SearchString.swift
//  Crush
//
//  Created by ezou on 2020/3/12.
//

import Foundation

public struct SearchString<T: Entity>: Equatable {
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
    public let placeholder: String
}

extension SearchString: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self.string = value
        self.type = .plain
        self.placeholder = "%@"
    }
}

public extension SearchString {
    static func caseInsensitive(_ string: String) -> SearchString {
        SearchString(type: .caseInsensitive, string: string, placeholder: "%@")
    }

    static func diacriticInsensitive(_ string: String) -> SearchString {
        SearchString(type: .diacriticInsensitive, string: string, placeholder: "%@")
    }

    static func caseDiacriticInsensitive(_ string: String) -> SearchString {
        SearchString(type: .caseDiacriticInsensitive, string: string, placeholder: "%@")
    }
}

// MARK: Extension for KeyPath

public extension SearchString {
    init<Root: Entity, Value: WritableProperty>(
        _ keyPath: KeyPath<Root, Value>, modifier: Category = .plain)
    where Value.PredicateValue == String
    {
        self.init(type: modifier,
                  string: keyPath.propertyName,
                  placeholder: "%K")
    }

    init<Root: Entity, Value: WritableProperty>(
        _ keyPath: KeyPath<Root, Value>, modifier: Category = .plain)
    where Value.PredicateValue: PredicateExpressibleByString
    {
        self.init(type: modifier,
                  string: "\(keyPath.propertyName).stringValue",
                  placeholder: "%K")
    }
}

public extension SearchString {
    static func caseInsensitive<Value: WritableProperty>(_ keyPath: KeyPath<T, Value>) -> SearchString
    where Value.PredicateValue == String {
        SearchString(type: .caseInsensitive,
                     string: keyPath.propertyName,
                     placeholder: "%K")
    }

    static func diacriticInsensitive<Value: WritableProperty>(_ keyPath: KeyPath<T, Value>) -> SearchString
    where Value.PredicateValue == String {
        SearchString(type: .diacriticInsensitive,
                     string: keyPath.propertyName,
                     placeholder: "%K")
    }

    static func caseDiacriticInsensitive<Value: WritableProperty>(_ keyPath: KeyPath<T, Value>) -> SearchString
    where Value.PredicateValue == String {
        SearchString(type: .caseDiacriticInsensitive,
                     string: keyPath.propertyName,
                     placeholder: "%K")
    }

    static func caseInsensitive<Value: WritableProperty>(_ keyPath: KeyPath<T, Value>) -> SearchString
    where Value.PredicateValue: PredicateExpressibleByString {
        SearchString(type: .caseInsensitive,
                     string: keyPath.propertyName,
                     placeholder: "%K")
    }

    static func diacriticInsensitive<Value: WritableProperty>(_ keyPath: KeyPath<T, Value>) -> SearchString
    where Value.PredicateValue: PredicateExpressibleByString {
        SearchString(type: .diacriticInsensitive,
                     string: keyPath.propertyName,
                     placeholder: "%K")
    }

    static func caseDiacriticInsensitive<Value: WritableProperty>(_ keyPath: KeyPath<T, Value>) -> SearchString
    where Value.PredicateValue: PredicateExpressibleByString {
        SearchString(type: .caseDiacriticInsensitive,
                     string: keyPath.propertyName,
                     placeholder: "%K")
    }
}

// MARK: Extension for FetchSource

public extension SearchString {
    init<Root: Entity, Value: WritableProperty>(
        _ fetchSource: FetchSource<Root, Value>, modifier: Category = .plain)
    where Value.PredicateValue == String
    {
        self.init(type: modifier,
                  string: fetchSource.expression,
                  placeholder: "%K")
    }

    init<Root: Entity, Value: WritableProperty>(
        _ fetchSource: FetchSource<Root, Value>, modifier: Category = .plain)
    where Value.PredicateValue: PredicateExpressibleByString
    {
        self.init(type: modifier,
                  string: "\(fetchSource.expression).stringValue",
                  placeholder: "%K")
    }
}

public extension SearchString {
    static func caseInsensitive<Value: WritableProperty>(_ fetchSource: FetchSource<T, Value>) -> SearchString
    where Value.PredicateValue == String {
        SearchString(type: .caseInsensitive,
                     string: fetchSource.expression,
                     placeholder: "%K")
    }

    static func diacriticInsensitive<Value: WritableProperty>(_ fetchSource: FetchSource<T, Value>) -> SearchString
    where Value.PredicateValue == String {
        SearchString(type: .diacriticInsensitive,
                     string: fetchSource.expression,
                     placeholder: "%K")
    }

    static func caseDiacriticInsensitive<Value: WritableProperty>(_ fetchSource: FetchSource<T, Value>) -> SearchString
    where Value.PredicateValue == String {
        SearchString(type: .caseDiacriticInsensitive,
                     string: fetchSource.expression,
                     placeholder: "%K")
    }

    static func caseInsensitive<Value: WritableProperty>(_ fetchSource: FetchSource<T, Value>) -> SearchString
    where Value.PredicateValue: PredicateExpressibleByString {
        SearchString(type: .caseInsensitive,
                     string: fetchSource.expression,
                     placeholder: "%K")
    }

    static func diacriticInsensitive<Value: WritableProperty>(_ fetchSource: FetchSource<T, Value>) -> SearchString
    where Value.PredicateValue: PredicateExpressibleByString {
        SearchString(type: .diacriticInsensitive,
                     string: fetchSource.expression,
                     placeholder: "%K")
    }

    static func caseDiacriticInsensitive<Value: WritableProperty>(_ fetchSource: FetchSource<T, Value>) -> SearchString
    where Value.PredicateValue: PredicateExpressibleByString {
        SearchString(type: .caseDiacriticInsensitive,
                     string: fetchSource.expression,
                     placeholder: "%K")
    }
}

