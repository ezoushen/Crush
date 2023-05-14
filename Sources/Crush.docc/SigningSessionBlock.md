# Signing Execution Block in Session

Enable signing `transactionAuthor` for the code block 

## What is transactionAuthor

`transactionAuthor` is a property of `NSManagedObjectContext` that identifies the author of the transaction. It is used to track the changes made by each user. 

## When to sign the transactionAuthor

You should sign the `transactionAuthor` when you are performing a data mutation operation in a session. 

## How to sign the transactionAuthor

You can sign the `transactionAuthor` by providing `name` parameter of the execution method, both of sync and async methods, in `Session`:

```swift

try session.sync(name: "John") { context in
    let entity = try context.create(MyEntity.self)
    entity.stringValue = "Hello world!"
    try context.commit()
}

```
## Where would the transactionAuthor be used

The `transactionAuthor` will be used in the `NSPersistentHistoryChange` object, which is used to track the changes made by each user. You can load the `NSPersistentHistoryChange` object by calling ``DataContainer/loadTransactionHistory(since:)``.

```swift
let transactions = try dataContainer.loadTransactionHistory(since: targetDate)

for transaction in transactions {
    let author = transction.author // signed author name 
}
```
