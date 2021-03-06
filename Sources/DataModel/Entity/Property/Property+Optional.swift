//
//  Property+Optional.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/12/31.
//  Copyright © 2019 ezou. All rights reserved.
//

import Foundation

public protocol Nullability {
    static var isOptional: Bool { get }
}

public struct Nullable: Nullability {
    public static var isOptional: Bool { true }
}

public struct NotNull: Nullability {
    public static var isOptional: Bool { false }
}
