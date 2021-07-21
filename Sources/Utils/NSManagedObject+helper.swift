//
//  NSManagedObject+helper.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
    func receive<T: NSManagedObject>(runtimeObject: T) -> T {
        let result = object(with: runtimeObject.objectID) as! T
        if runtimeObject.isFault == false {
            result.willAccessValue(forKey: T.entity().attributesByName.first!.key)
        }
        return result
    }
}
