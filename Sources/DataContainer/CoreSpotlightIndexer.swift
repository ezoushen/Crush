//
//  CoreSpotlightIndexer.swift
//  
//
//  Created by ezou on 2022/2/4.
//

#if os(iOS) || os(macOS)
import CoreData
import CoreSpotlight

public protocol CoreSpotlightAttributeSetProvider: AnyObject {
    func attributeSet(for object: NSManagedObject) -> CSSearchableItemAttributeSet?
}

internal class CoreSpotlightAttributeSetProviderProxy: CoreSpotlightAttributeSetProvider {

    let block: (NSManagedObject) -> CSSearchableItemAttributeSet?

    init(_ block: @escaping (NSManagedObject) -> CSSearchableItemAttributeSet?) {
        self.block = block
    }

    func attributeSet(for object: NSManagedObject) -> CSSearchableItemAttributeSet? {
        block(object)
    }
}

@available(iOS 13.0, macOS 10.15, *)
internal class CoreSpotlightDelegate: NSCoreDataCoreSpotlightDelegate {

    internal let provider: CoreSpotlightAttributeSetProvider

    internal init(
        provider: CoreSpotlightAttributeSetProvider,
        storeDescription: NSPersistentStoreDescription,
        coordinator: NSPersistentStoreCoordinator)
    {
        self.provider = provider
        super.init(forStoreWith: storeDescription, coordinator: coordinator)
    }

    internal override func domainIdentifier() -> String {
        Bundle.main.bundleIdentifier!
    }

    internal override func indexName() -> String? {
        Bundle.main.infoDictionary!["CFBundleName"] as? String
    }

    override func attributeSet(for object: NSManagedObject) -> CSSearchableItemAttributeSet? {
        provider.attributeSet(for: object)
    }
}

public class CoreSpotlightIndexer {

    let coreSpotlightDelegate: AnyObject

    @available(iOS 13.0, macOS 10.15, *)
    private func delegate() -> CoreSpotlightDelegate {
        return coreSpotlightDelegate as! CoreSpotlightDelegate
    }

    @available(iOS 13.0, macOS 10.15, *)
    public init(
        provider: CoreSpotlightAttributeSetProvider,
        storeDescription: NSPersistentStoreDescription,
        coordinator: NSPersistentStoreCoordinator)
    {
        coreSpotlightDelegate = CoreSpotlightDelegate(
            provider: provider, storeDescription: storeDescription, coordinator: coordinator)
    }


    @available(iOS 13.0, macOS 10.15, *)
    public func startIndexing() {
        delegate().startSpotlightIndexing()
    }

    @available(iOS 13.0, macOS 10.15, *)
    public func stopIndexing() {
        delegate().stopSpotlightIndexing()
    }

    @available(iOS 14.0, macOS 11.0, *)
    public func deleteIndex(completion: @escaping (Error?) -> Void) {
        delegate().deleteSpotlightIndex(completionHandler: completion)
    }
}
#endif
