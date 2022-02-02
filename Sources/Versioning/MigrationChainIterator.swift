//
//  MigrationChainIterator.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

internal class MigrationChainIterator: IteratorProtocol {
    internal struct Node {
        internal let name: String
        internal let mappingModel: NSMappingModel
        internal let destinationManagedObjectModel: NSManagedObjectModel
    }

    private var index: Int = 0

    internal let chain: MigrationChain

    internal init(_ chain: MigrationChain) {
        self.chain = chain
    }

    internal func next() -> Node? {
        guard let mappingModels = try? chain.mappingModels(),
              let managedObjectModels = try? chain.managedObjectModels(),
              mappingModels.count > index else { return nil }
        defer { index += 1 }
        return Node(
            name: chain.migrations[index+1].name,
            mappingModel: mappingModels[index],
            destinationManagedObjectModel: managedObjectModels[index+1])
    }

    internal func setActiveVersion(managedObjectModel: NSManagedObjectModel?) {
        guard let managedObjectModels = try? chain.managedObjectModels(),
              let managedObjectModel = managedObjectModel else {
                  return index = 0
              }
        index = managedObjectModels.firstIndex(of: managedObjectModel) ?? 0
    }

    internal func reset() {
        index = 0
    }
}
