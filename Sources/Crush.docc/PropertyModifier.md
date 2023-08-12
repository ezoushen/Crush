# Property Modifier

Crush provides multiple ways to modify the properties of an entity. This helps you separate concerns and configure a property by composition.

## Overview

In Crush, declaring properties is straightforward. You can define a property using the following syntax:

``` swift
let property = Value.Int16("property")
```

By default, properties are declared without requiring extensive configuration. However, if you need to fine-tune the behavior of a property, you can achieve this through the use of property modifiers.

### Using Property Modifiers

Property modifiers allow you to apply specific configurations to your properties. For instance, consider a scenario where you want to adjust the behavior of a property to make it optional and also mark it for indexing. You can achieve this using property modifiers.

Here's an example of declaring a property with property modifiers:

``` swift
@Indexed
@Optional
var property = Value.Int16("property")
```

In this example, the `@Indexed` modifier indicates that the property should be indexed, which can improve query performance. The `@Optional` modifier specifies that the property is optional, meaning it does not need to have a value.

By utilizing property modifiers, you can easily tailor the behavior of your properties to suit your specific needs, ensuring flexibility and efficiency in your codebase.

### General Modifers

- ``Optional``
- ``Required``
- ``Transient``
- ``Indexed``
- ``IndexedBySpotlight``
- ``Unique``

### Attribute Modifiers

- ``Default``
- ``ExternalBinaryDataStorage``
- ``Validation``
- ``PreservesValueInHistoryOnDeletion``

### Relationship Modifiers

- ``Inverse``
- ``MaxCount``
- ``MinCount``
- ``DeleteRule``
- ``UnidirectionalInverse``

> Tips: You can access all modifiers using ``PropertyModifiers``, ``AttributeModifiers``, and ``RelationshipModifiers``
