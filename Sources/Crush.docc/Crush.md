# ``Crush``

Enhance the development experience with CoreData by providing greater type-safety and intuitive functionality

## Overview

### Installation

Make sure you've declared `Crush` as your dependency before getting started 

```swift
let package = Package(
  dependencies: [
    .package(
      url: "https://github.com/ezoushen/Crush",
      from: "1.0.0"
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

## Topics

### Getting started

- <doc:Concepts>
- <doc:QuickStart>
- <doc:CRUDOperations>

### Working with Session

- <doc:IntroducingSession>
- <doc:TypesOfSessions>
- <doc:SigningSessionBlock>
- <doc:UndoRedoInSession>

### Managing data schema

### Query builders 
