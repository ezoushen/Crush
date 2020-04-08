//
//  ReadOnlyTransactionContext.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

internal struct _ReadOnlyTransactionContext: ReaderTransactionContext, RawContextProviderProtocol {
    internal let context: NSManagedObjectContext
    internal let targetContext: NSManagedObjectContext
    
    internal init(context: NSManagedObjectContext, targetContext: NSManagedObjectContext) {
        self.context = context
        self.targetContext = targetContext
    }
}

extension TransactionContextProtocol where Self: RawContextProviderProtocol {
    func count(request: NSFetchRequest<NSFetchRequestResult>) -> Int {
        var result: Int? = nil
        
        targetContext.performAndWait {
            do {
                result = try targetContext.count(for: request)
            } catch {
                print("Unabled to count the records, error:", error.localizedDescription)
            }
        }
        
        return result ?? 0
    }
    
    func execute<T>(request: NSFetchRequest<NSFetchRequestResult>) throws -> [T] {
        targetContext.processPendingChanges()

        return try targetContext.performAndWait {
            return try self.targetContext.fetch(request) as! [T]
        }
    }
    
    func execute<T: NSPersistentStoreResult>(request: NSPersistentStoreRequest) throws -> T {
        targetContext.processPendingChanges()

        return try targetContext.performAndWait {
            return try self.targetContext.execute(request) as! T
        }
    }
}
