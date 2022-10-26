# observer_design_pattern

Define a one-to-many dependency between objects so that when one object changes state, all its dependents are notified and updated automatically.
## Applicability
When having a collection of tightly couple objects in the system where changes for one object should trigger changes in the others(one-to-many relationship).
A good way to approach this is to implement a publish-subscribe mechanism that sends the update events to dependent objects so they could implement and maintain the update logic on their own.
To achieve this, the Observer design pattern introduces two roles: Subject and Observer.

The subject is the publisher of notifications which also defines a way for the observer to subscribe/unsubscribe from those notifications.
A subject may have any number of dependent observers(one-to-many relationship in more flexible way rather than create a method to maintain the update logic on their own).
## ScreenShots
(screen shot of observer design pattern usecase)[1.png]


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
