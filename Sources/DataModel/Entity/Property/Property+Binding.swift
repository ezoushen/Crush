//
//  Property+Binding.swift
//  Crush
//
//  Created by ezou on 2020/4/18.
//

#if canImport(SwiftUI)
import SwiftUI
import Combine

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
public func ??<T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
#endif
