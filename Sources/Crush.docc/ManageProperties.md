# Manage Properties

Configure properties within an entity in a declarative way.

## Attributes

You can retreive all the types supported by CoreData from ``Value``. You can declared an attribute as example below. 

``` swift
// This declare a bool attribute named "PROPERTY_NAME"
let boolValue = Value.Bool("PROPERTY_NAME")
```

## Relationships

You can retreive all the types supported by CoreData from ``Relation``. You can declared a relationship as example below.

- To-One Relationship

``` swift
// This declare a to-one relationship named "PROPERTY_NAME" to "TARGET_ENTITY"
let toOneRelationship = Relation.ToOne<TargetEntity>("PROPERTY_NAME")
```

- To-Many Relationship

``` swift
// This declare a to-many relationship named "PROPERTY_NAME" to "TARGET_ENTITY"
let toManyRelationship = Relation.ToMany<TargetEntity>("PROPERTY_NAME")
```

- To-Many Ordered Relationship

``` swift
// This declare a to-many ordered relationship named "PROPERTY_NAME" to "TARGET_ENTITY"
let toManyOrderedRelationship = Relation.ToManyOrdered<TargetEntity>("PROPERTY_NAME")
```

### Setup inverse relationship

Crush supports the equivalent feature of setting up an inverse relationship in `xcdatamodel` by using the property wrapper ``Inverse``. In most cases, you would want to create a two-way inverse using ``Inverse``, but for certain special cases, you may need to create a unidirectional inverse using the ``UnidirectionalInverse`` property wrapper.

```swift
// ChildEntity
@Inverse(\.children)
var parent = Relation.ToOne<ParentEntity>("parent")

// ParentEntity
var children = Relation.ToMany<ChildEntity>("children")
``` 

> Important: You only need to setup inverse relationship on either side of the relationship. 


## Advanced property features

### Derived Attribute

Derived property is a powerful feature of CoreData, it allows you to define a property that is computed from other properties. You can declare a derived property as example below.

``` swift
// This declare a derived bool property named "derivedProperty" from "PROPERTY_NAME"
let derivedProperty = Derived.Bool("derivedProperty", from: "PROPERTY_NAME")
```

### Fetched Property

Fetched property is also a powerful feature designed by CoreData, it helps you fetch entities based on the provided pre-defined predicate by only accessing this property. You can declare a fetched property as example below.

``` swift
let fetchedProperty = Fetched<TargetEntity>("fetchedProperty") { 
    $0.where(\.boolValue == true)
}
```
