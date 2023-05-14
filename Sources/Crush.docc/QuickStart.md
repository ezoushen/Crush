# Quick Start

This guide aims to provide an understanding of the foundational concepts of the framework before exploring its comprehensive feature set.

## Overview

We offer an entry point named ``DataContainer``, which is similar to `CoreData`. To initialize a ``DataContainer``, you must provide at least one ``Storage`` instance and a valid ``DataModel``. You can create a `DataContainer` by calling the ``DataContainer/load(storages:dataModel:mergePolicy:migrationPolicy:)`` method:

## Creating DataModel

To define a ``DataModel``, you must begin by defining entities and setting up the hierarchy between them. You can do this by calling the ``DataModel/init(name:_:)`` method.

### Defining entities

You have to declare a class inheriting from ``Entity`` (or a subclass), and define all its properties as instance properties inside.

```swift
class Todo: Entity {
    @Required
    var title = Value.String("title") // A required string property named "title"

    @Optional
    var memo = Value.String("memo") // An optional string property named "memo"

    @Required
    @Default(false)
    var finished = Value.Bool("finished")

    @Optional
    var parent = Relation.ToOne<Todo>("parent") // An optional relationship to another Todo

    @Optional
    @Inverse(\.parent)
    var children = Relation.ToMany<Todo>("children")
}
```

To exploring more supported property types, please refer to ``Value``, ``Relation``, ``Derived``, and ``Fetched``

### Composing entities

```swift
let dataModel = DataModel(name: "Model Name", [
    // Abstract class
    Abstract(MyAbstractEntity(), inheritance: .multiTable),
    // Concrete class
    MyConcreteEntity() 
])
```

## Creating Storage

All store types defined in `CoreData` are supported, including xml (macOS only), ``Storage/binary(url:configuration:options:)``, ``Storage/inMemory(configuration:options:)``, and ``Storage/sqlite(url:configuration:options:)``.

## Putting it all together

```swift
let container = try DataContainer.load(storages: .inMemory(), dataModel: myDataModel)
```

Fore more details, you can learn how to use it in ``DataContainer`` page. After creating a data container, now you can access and modify data through the ``Session`` object. The following code snippet shows how to create a new ``Todo`` object and save it to the database.

 
```swift
let session = try container.startSession()

session.sync { context in
    let todo = context.create(Todo.self)
    todo.title = "Hello Crush"
    try context.commit()
}
```
