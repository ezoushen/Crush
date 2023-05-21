# Crush

Enhance the development experience with CoreData by providing greater type-safety and intuitive functionality

## Overview

Take full control of your CoreData management. 
100% managed code, no code generation required. 
Free from Xcode GUI, and human-friendly diff records on git.

### Installation

Make sure you've declared `Crush` as your dependency before getting started 

```swift
let package = Package(
  dependencies: [
    .package(
      url: "https://github.com/ezoushen/Crush",
      from: "TARGET_VERSION"
    ),
  ],
  targets: [
    .target(
      name: "<your-target-name>",
      dependencies: [
        "Crush"
      ]
    )
  ]
)
```

## Usage

Only three steps to start using Crush

### Define your schema

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

### Create your DataContainer

```swift
let container = try DataContainer.load(
    storages: .sqlite(url: targetURL), 
    dataModel: DataModel(name: "V1", [ Todo() ]))
```

### Start coding!

```swift
try container.sync { context in
    let todo = context.create(Todo.self)
    todo.title = "Hello Crush"
    try context.commit()
}
```

## Documentation

Swift DocC style documentation is available [here](https://ezoushen.github.io/Crush/documentation/crush)

## Coorporation

If you want to contribute to the project, please feel free to open a pull request/issue. 
