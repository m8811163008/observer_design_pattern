/// [Publisher] (Subject)- provides an interface for attaching
/// and detaching [Subscriber] (observer) objects, contains a
/// list of observers.
class Publisher {
  final _subscribers = <Subscriber>[];
  final _mainState = Context();

  void subscribe(Subscriber subscriber) => _subscribers.add(subscriber);

  void unsubscribe(Subscriber subscribe) => _subscribers.remove(subscribe);

  void notifySubscribes() {
    for (var subscriber in _subscribers) {
      subscriber.update(_mainState);
    }
  }

  void mainBusinessLogic() {
    _mainState.mainState = 'newState';
    notifySubscribes();
  }
}

class Context {
  var mainState = '1';
}

/// Declares the notification interface for objects that
/// should be notified of changes in a [Publisher](subject).
abstract class Subscriber {
  void update(context);
}

/// Implements the [Subscriber](Observer) interface to keep
/// its state consistent with the subject's state.
class ConcreteSubscribersA extends Subscriber {
  /// Consistent with the subject's state.
  @override
  void update(context) {
    print('ConcreteSubscribersA $context');
  }
}

class ConcreteSubscribersB extends Subscriber {
  @override
  void update(context) {
    print('ConcreteSubscribersB $context');
  }
}

void main() {
  final s = ConcreteSubscribersB();
  final publisher = Publisher();
  publisher.subscribe(s);
  publisher.mainBusinessLogic();
}
