//
//  CollectionBuilder.swift
//  
//
//  Created by ezou on 2021/10/16.
//

import Foundation

@resultBuilder
public struct CollectionBuilder<T> {
    public static func buildBlock(_ components: T...) -> [T] {
        return components
    }
}


@resultBuilder
public struct SetBuilder<T: Hashable> {
    public static func buildBlock(_ components: T...) -> Set<T> {
        return Set(components)
    }
}

@resultBuilder
public struct OrderedSetBuilder<T: Hashable> {
    public static func buildBlock(_ components: T...) -> OrderedSet<T> {
        return OrderedSet(components)
    }
}

