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

@available(iOS 13.0, *)
extension Attribute: ObservableObject {
    public func binding() -> Binding<PropertyValue> {
        Binding(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

@available(iOS 13.0, *)
extension Temporary: ObservableObject {
    public func binding() -> Binding<PropertyValue> {
        Binding(
            get: { self.property.wrappedValue },
            set: { self.property.wrappedValue = $0 }
        )
    }
}

@available(iOS 13.0, *)
extension Relationship: ObservableObject {
    public func binding() -> Binding<PropertyValue> {
        Binding(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

#endif
