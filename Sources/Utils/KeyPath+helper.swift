//
//  KeyPath+helper.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import Foundation
import CoreData

public protocol Expressible {
    func asExpression() -> Any
}

extension KeyPath: Expressible where Root: Entity, Value: PropertyProtocol {
    public func asExpression() -> Any {
        propertyName
    }
}
