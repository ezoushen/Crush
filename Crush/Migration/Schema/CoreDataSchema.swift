//
//  CoreDataSchema.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/2/6.
//

import Foundation

enum CoreDataSchemaError: Error {
    case modelNotFound
}

public struct CoreDataSchema: SchemaProtocol {
    public var model: ObjectModel {
        concreteVersion!.model
    }

    private let schemaChain: [CoreDataMomSchema]
    
    public var lastVersion: SchemaProtocol?

    public var concreteVersion: SchemaProtocol?

    public init() { fatalError("Dummy initializer should not be trigggered") }

    public init(name: String, sort: (String, String) -> Bool = { $0 < $1 } ) throws {
        guard let url = Bundle.main.url(forResource: name, withExtension: "momd"),
            let files = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])) ?? {
                guard let momUrl = Bundle.main.url(forResource: name, withExtension: "mom") else { return nil }
                return FileManager.default.fileExists(atPath: momUrl.path) ? [momUrl] : nil
            }() else {
            throw CoreDataSchemaError.modelNotFound
        }
        
        let versionUrl = files.first(where: { $0.absoluteString.hasSuffix("plist") })
        let versionName: String = {
            guard let url = versionUrl else { return name }
            return (NSDictionary(contentsOf: url)?["NSManagedObjectModel_CurrentVersionName"] as? String) ?? name
        }()
        
        schemaChain = files
            .filter{
                $0.lastPathComponent.hasSuffix("mom") == true
            }
            .sorted{
                sort($0.lastPathComponent, $1.lastPathComponent)
            }
            .reduce([CoreDataMomSchema]()) {
                return $0 + [CoreDataMomSchema(url: $1, previous: $0.last)]
            }
        
        concreteVersion = schemaChain.first{
            $0.name.split(separator: ".").first?.elementsEqual(versionName) ?? false
        }
    }
}

internal class CoreDataMomSchema: SchemaProtocol {
    
    var model: ObjectModel
    
    var lastVersion: SchemaProtocol?
    
    var concreteVersion: SchemaProtocol? {
        return self
    }
    
    var name: String
    
    required init() { fatalError("Dummy initializer should not be trigggered") }
    
    init(url: URL, previous: CoreDataMomSchema?) {
        self.name = url.lastPathComponent
        self.lastVersion = previous
        self.model = CoreDataModel(url: url, previousModel: previous?.model)
    }
}
