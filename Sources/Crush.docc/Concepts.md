# Concepts

Basic concepts behind `Crush`

## What is Crush

`Crush` is a framework that facilitates interacting with CoreData features in a Swifty and type-safe manner. It differs from vanilla CoreData in several ways, such as the CoreData stack, schema declaration, concurrency management, and data migration.

### CoreData stack

Compared to `NSPersistentContainer`, the CoreData stack used in ``DataContainer`` by Crush is slightly different. Rather than connecting the viewContext directly to the `NSPersistentStoreCoordinator`, Crush introduces an additional intermediate background context. This context is responsible for committing changes to the coordinator and merging changes into the UI context in-memory.

![CoreData stack](CoreDataStack)

In the Crush CoreData stack, there are two long-lived contexts: the UI context and the Writer context. The UI context is responsible for presenting data on the main thread, while the Writer context is responsible for pushing changes to the persistent store coordinator. All data mutation must be done in a background context and will only be shown in the UI context after being saved to the persistent store successfully.

By adopting this approach, we can ensure that the main thread is free from direct communication with the database. This separation of concerns allows for a smoother user experience and helps prevent issues such as UI lag or freezes.

### Schema declaration

In traditional CoreData, data models are managed through `.xcdatamodel` files, which can be difficult to maintain across multiple Xcode versions and collaborations. Managing data models through code can offer greater flexibility and ease of maintenance.

There're some simple examples in <doc:QuickStart>.

### Concurrency management

In `CoreData`, direct data access in `NSManagedObject` is not thread-safe. Thus, in `Crush`, data mutation is allowed only in limited contexts. To achieve this, two object types are introduced: `ManagedObject` and `ReadOnly`.

- ``ManagedObject``: A subclass of `NSManagedObject` that is responsible for calling `CoreData` APIs.
- ``ReadOnly``: A class responsible for thread-safe data access of the managed object.

With these two classes, we can guarantee thread-safe data access from any ``ReadOnly`` object (possibly reentrant safe). All managed objects should be used only in the callback block of ``Session/sync(name:block:)-7nr4q`` or ``Session/async(name:block:completion:)`` (and other sync and async methods provided in ``Session``).

```swift
let myEntity: ReadOnly<MyEntity>
try dataContainer.startSession().sync { context in
  let mutableEntity = context.edit(myEntity)
  // Do something
  mutableEntity.integerValue = 10
  try context.commit()
}
print(myEntity.integerValue) // 10
```
