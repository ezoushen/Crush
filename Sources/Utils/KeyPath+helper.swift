//
//  KeyPath+helper.swift
//  Crush
//
//  Created by ezou on 2019/9/20.
//  Copyright © 2019 ezou. All rights reserved.
//

import Foundation
import CoreData

public protocol KeyPathProvider {
    func getKeyPathString(_ keyPath: AnyKeyPath) -> String?
}

public enum KeyPathProviderContainer {
    public static var provider: KeyPathProvider!
}

extension AnyKeyPath {
    public var stringValue: String {
        KeyPathProviderContainer.provider.getKeyPathString(self)!
    }
}

public protocol Expressible {
    func asExpression() -> Any
}

public protocol RootTracableKeyPathProtocol: Expressible {
    var rootType: Entity.Type { get }
    var keyPath: AnyKeyPath { get }
    var stringValue: String { get }
}

extension KeyPath: Expressible where Root: RuntimeObject {
    public func asExpression() -> Any {
        stringValue
    }
}

extension KeyPath: RootTracableKeyPathProtocol where Root: NeutralEntityObject, Value: Field {
    public var rootType: Entity.Type {
        return Root.self
    }

    public var keyPath: AnyKeyPath {
        return self
    }
}
