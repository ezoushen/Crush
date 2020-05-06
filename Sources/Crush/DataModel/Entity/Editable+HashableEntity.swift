//
//  Editable+HashableEntity.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/5/6.
//

import Foundation

@dynamicMemberLookup
public final class Editable<Value: HashableEntity> {
    let value: Value.ReadOnly
    let transaction: Transaction
    
    init(_ value: Value.ReadOnly, transaction: Transaction) {
        self.value = value
        self.transaction = transaction
    }
    
    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    public func bindings() -> Bindable<Value> {
        Bindable(self)
    }
    
    public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<Value, Subject>) -> Subject {
        get {
            try! transaction.edit(value).sync { context, value in
                value[keyPath: keyPath]
            }
        }
        set {
            try! transaction.edit(value).sync { context, value in
                value[keyPath: keyPath] = newValue
            }
        }
    }
}
