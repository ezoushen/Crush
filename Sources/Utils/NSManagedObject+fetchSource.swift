//
//  NSManagedObject+FetchSource.swift
//  
//
//  Created by EZOU on 2023/4/28.
//

import CoreData
import Foundation

extension NSManagedObjectID {
    open override func value(forUndefinedKey key: String) -> Any? {
        guard let fetchSource = NSManagedObject.currentFetchSource else { return nil }
        let value = fetchSource.value(forKey: key)
        return value
    }
}

extension NSManagedObject {
    /// This is a thread local variable. It represents the current fetch source as
    /// the target of `$FETCH_SOURCE` in the fetch property of a fetched property.
    @ThreadLocal static var currentFetchSource: NSManagedObject? = nil
}
