//
//  Bindable+HashableEntity.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/5/6.
//

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
@dynamicMemberLookup
public struct Bindable<E: HashableEntity> {
    public let entity: Editable<E>
    
    init(_ entity: Editable<E>) {
        self.entity = entity
    }
    
    public subscript<Subject: Field>(dynamicMember keyPath: ReferenceWritableKeyPath<E, Subject>) -> Binding<Subject> {
        Binding<Subject>(
            get: { self.entity[dynamicMember: keyPath] },
            set: { self.entity[dynamicMember: keyPath] = $0 }
        )
    }
}
#endif
