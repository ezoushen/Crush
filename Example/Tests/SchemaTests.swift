import XCTest
@testable import Crush

fileprivate class V1: Schema<FirstVersion> {
    class Animal: AbstractEntityObject {
        class Index: NSObject, IndexSetProtocol {
            @FetchIndex<Animal>
            var name = AscendingIndex(\.$name)
        }
        
        @Value.String
        var name: String
        
        @Optional.Relation.ManyToOne<Animal, Person>(inverse: \.$pets)
        var owner: Person?
    }
    
    class Dog: Animal {
        @Value.String
        var bark: String
    }
    
    class Cat: Animal {
        @Value.String
        var meow: String
    }
    
    class Person: EntityObject {
        @Value.String
        var familyName: String
        
        @Relation.OneToMany<Person, Animal>
        var pets: Set<Animal>
        
        @Relation.OneToOne<Person, Animal>
        var favorite: Animal
    }
}

fileprivate class V2: Schema<V1> {
    class Animal: AbstractEntityObject {
        class Index: NSObject, IndexSetProtocol {
            @FetchIndex<Animal>
            var name = AscendingIndex(\.$name)
        }
        
        @Value.String
        var name: String
        
        @Optional.Relation.ManyToOne<Animal, Person>(inverse: \.$pets)
        var owner: Person?
    }
    
    class Dog: Animal {
        @Value.String(options: [
            PropertyOption.mapping(\LastVersion.Dog.$bark)
        ])
        var howl: String
    }
    
    class Cat: Animal {
        @Value.String
        var meow: String
    }
    
    class Person: EntityObject {
        @Value.String
        var familyName: String
        
        @Relation.OneToMany<Person, Animal>
        var pets: Set<Animal>
        
        @Relation.OneToOne<Person, Animal>
        var favorite: Animal
    }
}

class SchemaTests: XCTestCase {
    let v1Model = V1.model
    
    func test_Schema_DataModel() {
        XCTAssert(v1Model.previousModel == nil, "Previous model should be nil")
        XCTAssert(v1Model.migration == nil, "Migration should be nil")
        XCTAssert(v1Model.objectModel != nil, "MOM should not be nil")
    }
    
    func test_Schema_DataModel_NSManagedObjectModel() {
        XCTAssert(v1Model.objectModel.entities.count == 4, "expected \(4), received, \(v1Model.objectModel.entities.count)")
        XCTAssert(v1Model.objectModel.versionIdentifiers == [String(reflecting: V1.self)])
    }
    
}
