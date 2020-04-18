//
//  Property+Binding.swift
//  Crush
//
//  Created by ezou on 2020/4/18.
//

import Foundation
#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, *)
public func ??<T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

extension Attribute {
    @available(iOS 13.0, *)
    public func binding() -> Binding<PropertyValue> {
        Binding(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

extension Temporary {
    @available(iOS 13.0, *)
    public func binding() -> Binding<PropertyValue> {
        guard case var .transient(attribute) = self else {
            fatalError("Trasient type mismatch")
        }
        
        return Binding(
            get: { attribute.wrappedValue },
            set: { attribute.wrappedValue = $0 }
        )
    }
}

extension Relationship {
    @available(iOS 13.0, *)
    public func binding() -> Binding<PropertyValue> {
        Binding(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

#endif
