//
//  NSEntityDescription+helper.swift
//  
//
//  Created by ezou on 2021/10/24.
//

import CoreData
import Foundation

extension NSEntityDescription {
    var entityType: Entity.Type? {
        guard let entityClassName =
                userInfo?[UserInfoKey.entityClassName] as? String
        else { return nil }
        return NSClassFromString(entityClassName) as? Entity.Type
    }
}
