# CRUD Operations

Simple example of CRUD Operations in Crush

## Start with Session

All data mutation in Crush must be completed through a ``Session``. You can create a session by calling ``DataContainer/startSession(name:)``. All data mutation would not be persisted until you call ``Session/commit()``.


```swift
let session = dataContainer.startSession()

try session.sync { context in
    /*
        Do something
    */
    try context.commit() // Persist the changes
}
```

## Create Operation

You can create an entity by calling ``SessionContext/create(entity:)``

```swift
try session.sync { context in
    let todo = context.create(entity: Todo.self)
    todo.title = "todo title"
    // setup the entity
    try context.commit()
}
```

## Read Operation

### Load by NSManagedObjectID

You can load an entity by calling ``SessionContext/load(objectID:)``

```swift 
session.sync { context in
    let todo = context.load(objectID: injectedObjectID)
}
```

### Fetch objects

You can fetch objects by building a fetch request through ``SessionContext/fetch(for:)``

```swift
session.sync { context in
    let todo = context.fetch(for: Todo.self)
        .where(\.title == "target title")
        .findOne()
}
```

## Update Operation

You can edit a readonly object by ``SessionContext/edit(object:)``

```swift
try session.sync { context in
    let editableTodo = context.edit(object: todo)
    editableTodo.title = "new title"
    try context.commit()
}
```

## Delete Operation

You can delete an object by ``SessionContext/delete(_:)``

```swift
try session.sync { context in
    context.delete(todo)
    try context.commit()
}
```

## Batch Operation

In Core Data
