# Undo/Redo In Session

Core Data supports undo/redo by default. In Crush, the redo/undo stack is managed through ``Session``

## How to enable undo/redo

To enable undo/redo, you need to call ``Session/enableUndoManager()``. And the session would start tracking the change stack block by block. Also, you can disable undo/redo by calling ``Session/disableUndoManager()``.

## Example of usage

```swift
let session = dataContainer.startInteractiveSession()

session.enableUndoManager()

let todo: Todo.ReadOnly = session.sync { context in
    // make changes
    let todo = context.create(entity: Todo.self)
    todo.title = "ORIGINAL TITLE"
    return todo
}

session.sync { context in
    let todo = context.edit(object: todo)
    todo.title = "NEW TITLE"
}

print(todo.title) // NEW TITLE

session.undo()

print(todo.title) // ORIGINAL TITLE

session.redo()

print(todo.title) // NEW TITLE

```

Please be aware of that the undo/redo stack is not enabled by default. You need to call ``Session/enableUndoManager()`` to enable it. And the undo/redo stack is flushed once the session committed.

