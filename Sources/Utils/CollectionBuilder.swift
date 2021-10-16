//
//  CollectionBuilder.swift
//  
//
//  Created by ezou on 2021/10/16.
//

import Foundation

@resultBuilder
struct CollectionBuilder<T> {
    static func buildBlock(_ components: T...) -> [T] {
        return components
    }
}

extension CollectionBuilder where T: Hashable {
    static func buildBlock(_ components: T...) -> Set<T> {
        return Set(components)
    }
}
