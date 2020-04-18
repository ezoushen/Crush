//
//  ViewModel.swift
//  Example-SwiftUI
//
//  Created by ezou on 2020/4/18.
//

import SwiftUI

protocol ViewModel {
    func binding<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>) -> Binding<T>
}

extension ViewModel {
    func binding<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>) -> Binding<T> {
        Binding(
            get: { self[keyPath: keyPath] },
            set: { self[keyPath: keyPath] = $0 }
        )
    }
}
