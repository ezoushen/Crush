//
//  TestModel.swift
//  
//
//  Created by ezou on 2021/10/9.
//

import Crush

class V1: SchemaOrigin {
    override var descriptions: [EntityDescription] {
        [
            EntityDescription(type: Creature.self, inheritance: .abstract),
            EntityDescription(type: People.self, inheritance: .concrete),
            EntityDescription(type: Dog.self, inheritance: .concrete)
        ]
    }
    
    class Creature: Entity {
        required init() { }
        let age = Required.Value.Int16("age")
    }

    class People: Creature {
        let firstName =
            Optional.Value.String("firstName")
        let lastName =
            Required.Value.String("lastName")
        
        let favoriteDog =
            Optional.Relation.ToOne<People, Dog>(
                "favorite_dog",
                inverse: \.master,
                options: [RelationshipOption.unidirectionalInverse])
        let mate =
            Optional.Relation.ToOne<People, People>("mate", inverse: "mate")
        let dogs =
            Optional.Relation.ToMany<People, Dog>("dogs")
        let friends =
            Optional.Relation.ToMany<People, People>("friends", inverse: "friends")
    }
    
    class Dog: Creature {
        let name = Required.Value.String("name")
        let master = Optional.Relation.ToOne<Dog, People>("master", inverse: \.dogs)
    }
}
