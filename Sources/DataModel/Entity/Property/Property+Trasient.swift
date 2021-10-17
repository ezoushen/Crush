//
//  Property+Trasient.swift
//  Crush
//
//  Created by ezou on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import Foundation

public protocol Transience {
    static var isTransient: Bool { get }
}

public struct NonTransient: Transience {
    public static var isTransient: Bool { false }
}

public struct Transient: Transience {
    public static var isTransient: Bool { true }
}
