# Types of Sessions

Introduce provided session types

## General Session

This is the default session type. It is suitable for most use cases. The execution context, which is derived from the writer context, is created in a background thread. And the read only objects are presented in the UI context which working on main thread.

Typically, this type of session mutates data in the background and presents data in the main thread. And the data mutation is unavailable until changes are saved.

## Interactive Session

This session type is suitable for interactive use cases. The execution context, which is derived from the writer context, is created in the main thread and the read only objects are presented in the UI context which working on main thread.

The use case of this session type is to perform data mutation in the main thread, and present data in the main thread. It is suitable for interactive use cases, such as editing data in a form. All changes are available during the session regardless .

## Detached Session

The execution context for this type of Session is directly connected to the persistent store coordinator, making it similar to a remote session. Changes made in this session won't be applied to the core data stack of the data container until they are fully committed. This session type is ideal for background tasks, such as background syncing.

## Table of comparison between different session types

| Session Type | Execution Thread | Parent of the execution context | UI Context | Writer Context | Use Case |
| --- | --- | --- | --- | --- | --- |
| General Session | Background thread | The writer context | Main UI context | The writer context | Apply data changes into the database
| Interactive Session | Main thread | The writer context | The writer context | The writer context | Interactive data editing
| Detached Session | Background thread | The PSC | Main UI context | The writer context | Background syncing
