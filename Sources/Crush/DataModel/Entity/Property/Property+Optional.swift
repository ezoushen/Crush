//
//  Property+Optional.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/12/31.
//  Copyright © 2019 ezou. All rights reserved.
//

import Foundation

public protocol OptionalTypeProtocol {
    static var isOptional: Bool { get }
}

public struct Nullable: OptionalTypeProtocol {
    public static var isOptional: Bool { true }
}

public struct NotNull: OptionalTypeProtocol {
    public static var isOptional: Bool { false }
}
