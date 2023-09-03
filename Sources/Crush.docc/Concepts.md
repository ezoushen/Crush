# Concepts

Basic concepts behind `Crush`

## What is Crush

`Crush` is a framework that facilitates interacting with CoreData features in a Swifty and type-safe manner. It differs from vanilla CoreData in several ways, such as schema declaration, concurrency management, more powerful predicate builder (thanks to operator overloading), and data migration.

### Schema declaration

In traditional CoreData, data models are managed through `.xcdatamodel` files, which can be difficult to maintain across multiple Xcode versions and collaborations. Managing data models through code can offer greater flexibility and ease of maintenance.

There're some simple examples in <doc:QuickStart>.

### Concurrency management

In `CoreData`, direct data access in `NSManagedObject` is not thread-safe. Thus, in `Crush`, data mutation is allowed only in limited contexts. To achieve this, two object types are introduced: `ManagedDriver` and `ReadOnly`.

- ``ManagedDriver``: A class responsible for proxying `CoreData` API calls.
- ``ReadOnly``: A class responsible for thread-safe data access of the managed object.

With these two classes, we can guarantee thread-safe data access from any ``ReadOnly`` object (possibly reentrant safe). All managed objects should be used only in the callback block of ``Session/sync(name:block:)-831hn`` or ``Session/async(name:block:completion:)`` (and other sync and async methods provided in ``Session``).

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

### Predicate Builder

In `Crush`, predicates are built using operator overloading. This allows for a more concise, type-safe, error-prone and readable syntax.

```swift
container
    .fetch(MyEntity.self)
    .where(\.stringValue <> "some string") // stringValue CONTAINS "some string"
    .andWhere(\.intValue > 10)             // AND intValue > 10
    .exec()
```

### Data Migration

Based on the data migration provided by `CoreData`, `Crush` offers a more flexible approach to data migration, including:

- Lightweight migration
- Heavyweight migration:
    - Ad-Hoc (version-to-version)
    - Incremental (migration chain)
    - Hybrid (uses Ad-Hoc if version matched, otherwise iterates through the provided chain)

You can choose your own migration policy through `migrationPolicy` of factory method of ``DataContainer``. 

