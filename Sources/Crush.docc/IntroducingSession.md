# Introducing Session

This article explains what a `Crush/Session` is and how to use it.

## What is Session?

A ``Session`` is a lightweight object that represents a single unit of work with the database. It provides a collection of methods that allow you to create, fetch, and delete objects in the database. More importantly, it manages the lifecycle of the `NSManagedObjectContext` and ensures that all data mutations are thread-safe.

### Structure of a Session

A session is composed of three `NSManagedObjectContext`s, each with a different purpose:

- **Execution context**: This context is responsible for performing data mutations.
- **UI context**: This context is responsible for presenting data on the main thread.
- **Writer context**: This context is responsible for pushing changes to the persistent store coordinator.

By separating the execution context and the UI context, we can ensure that the main thread is free from direct communication with the database. This separation of concerns allows for a smoother user experience and helps prevent issues such as UI lag or freezes.

You don't need to worry about the lifecycle of these contexts. The ``Session`` will automatically create and dispose of them for you, and also, data mutation methods are exposed through ``SessionContext`` APIs. The only decision to make is whether to execute these commands synchronously or asynchronously.

### Data isolation

Each ``Session`` is isolated from other ``Session``s. This means that changes made in one session will not be visible to other sessions until they are committed. This allows you to perform multiple operations in parallel without worrying about data conflicts. However, you still need to be aware of data conflicts between different ``Session``s and make sure they are handled properly by the merge policy or error handler.

## How to use Session

Using ``Session``, you can easily perform CRUD operations on the database:

```swift
let session = try dataContainer.startSession()
try session.sync { context in
  let todo = try context.create(Todo.self)
  todo.title = "Hello world!"
  try context.commit()
}
```

