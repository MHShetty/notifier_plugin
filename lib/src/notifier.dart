part of notifier_plugin;

/// A [Notifier] is a simple object that internally maintains a set of listeners and notifies them whenever
/// it is asked to. While a Notifier might just seem like being capable of doing just that, this plugin
/// has interfaced the same list of listeners with methods by re-using Dart in such a way that you can,
///
/// * Pass a single [Notifier] to an [Iterable]<Notifier> variable/parameter
/// * Add one/multiple listeners to one/multiple notifiers.
/// * Attach/detach one/multiple notifier(s) to one/multiple notifier(s)
/// * Make one/multiple notifier(s) listen to one/multiple notifier(s)
/// * (Un)lock a notifier to prevent addition/deletion of listeners
/// * Poll a notifier for a fixed number of times or over a fixed duration.
/// * Attach a Stream/ChangeNotifier to a Notifier.
/// * Notify/delete a specific (set of) listener(s) by just knowing its/their hashCode(s) or references
/// * Merge one/multiple notifier(s) into a single notifier
/// * Re-init a disposed notifier.
/// * Clear the listeners of a notifier.
/// * Check the state of the notifier through different getter/setter methods.
/// * Use the - operator to attach a WidgetBuilder(/handled function) to a Notifier (abstract)
class Notifier extends Iterable<Notifier> {

  List<Function> _listeners = <Function>[]; // Auto-init
  bool Function(Function,dynamic) _handleError;

  /// This constructor instantiates a [Notifier].
  ///
  /// * The named parameter [attachedNotifiers] attaches the given notifier(s) given to it.
  ///
  /// * The named parameter [listenToNotifiers] listens to notifiers given to it, once its
  /// instantiated.
  ///
  /// * The named parameter [mergeNotifiers] merges the other notifiers given to it/adds the
  /// listeners of those notifiers available at that point of time (static).
  ///
  /// * The named parameter [initialListeners] can be used to pass a set of listeners that would
  /// added to it, as soon as it is instantiated.
  Notifier({
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool lockListenersOnInit = false,
    bool Function(Function,dynamic) removeListenerOnError,
  }) {
    if (mergeNotifiers != null) _addListeners(mergeNotifiers._listeners);
    if (attachNotifiers != null) _attach(attachNotifiers);
    if (listenToNotifiers != null) _startListeningTo(listenToNotifiers);
    if (initialListeners != null) _addListeners(initialListeners);
    this.._handleError = removeListenerOnError;
    if(lockListenersOnInit==true) _listeners = List.from(_listeners, growable: false);
    WidgetsFlutterBinding.ensureInitialized();
  }

  Notifier._();

  /// This method polls a Notifier with notifications over a fixed [duration] of time and returns
  /// the current instance of [Notifier] as a [Future]. A TickerProvider can be provided to this
  /// method via the [vsync] parameter.
  Future<Notifier> pollFor(Duration duration, {TickerProvider vsync}) {
    if (_isNotDisposed) {
      Ticker t;
      Function onTick = (d) {
        if (d > duration) {
          t..stop()..dispose();
          return;
        }
        call();
      };
      t = vsync == null ? Ticker(onTick) : vsync.createTicker(onTick);
      return t.start().then((v) => this);
    }
    return null;
  }

  /// This method polls a Notifier with notifications for a fixed number of [times] and returns the
  /// duration taken to poll the Notifier as a future. A TickerProvider can be passed via the
  /// [vsync] parameter.
  Future<Duration> poll(int times, {TickerProvider vsync}) {
    Duration end;
    if (_isNotDisposed) {
      if (times < 0) times = -times; // abs
      if (times == 0) return Future.value(Duration.zero);
      Ticker t;
      Function onTick = (d) {
        if (times-- == 0) {
          end = d;
          t
            ..stop()
            ..dispose();
        }
        this();
      };
      t = vsync == null ? Ticker(onTick) : vsync.createTicker(onTick);
      return t.start().then((value) => end);
    }
    return null;
  }


  /// A method that notifies the listeners of the current [Notifier], whenever the passed Future
  /// completes or if it has already completed. You can tell the method what needs to be done
  /// if Future completes/has completed with an error or with an value.
  ///
  /// This is different from load(ing) the error onto a [ValNotifier]. (It cannot be strongly
  /// supported due to type issues)
  void notifyOnComplete<R>(Future<R> res,[Function(R) onData, Function onError]) => res.then(onData??(_){}).catchError(onError??(){}).whenComplete(this);

  /// A method that notifies the listeners of the current [Notifier], if the passed Future completes
  /// with an error else nothing is done with the [Notifier]. You can tell the method what needs to be
  /// done if the Future completes/has completed with an error or value.
  ///
  /// This is different from load(ing) the thrown error onto a [ValNotifier].
  void notifyIfError(Future res,[Function(dynamic) onData, Function onError]) =>
      res.then(onData??(_){}).catchError((e){
        if(onError!=null) onError is Function()?onError():onError(e);
        this();
      });

  /// A method that notifies the listeners of the current [Notifier], if the passed Future completes
  /// with an error else nothing is done with the [Notifier]. You can tell the method what needs to
  /// be done if the Future completes/has completed with an value or error.
  ///
  /// This is different from load(ing) the data received after awaiting a Future onto a
  /// [ValNotifier].
  void notifyIfSuccess<R>(Future<R> res, [Function(R) onData, Function onError]) =>
      res.then((_){
        onData?.call(_);
        this();
      }).catchError(onError??(){});

  /// The method [notifyAtInterval] notifies the current [Notifier] at the given/passed [interval].
  ///
  /// The notification that shall come at fixed interval can be be stopped by calling [Timer.cancel]
  /// on the [Timer] that's returned by this method.
  ///
  /// If null is explicitly passed to this method, it'll automatically get resolved to
  /// [Duration.zero].
  Timer notifyAtInterval(Duration interval) => _isNotDisposed ? Timer.periodic(interval??Duration.zero, (timer)=>this()) : null;

  /// Attach a [ChangeNotifier] to this [Notifier].
  ///
  /// Attaches the passed [changeNotifier] and returns true, if it wasn't previously attached else
  /// just returns false.
  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  bool attachChangeNotifier(ChangeNotifier changeNotifier) => _isNotDisposed?addListener(changeNotifier.notifyListeners)!=null:null;

  /// Detach a [ChangeNotifier] from this [Notifier].
  ///
  /// Detaches the passed [changeNotifier] and returns true if it was previously attached, else
  /// just returns false.
  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  bool detachChangeNotifier(ChangeNotifier changeNotifier) => _isNotDisposed?removeListener(changeNotifier.notifyListeners):null;

  /// Checks if the [Notifier] has attached this [ChangeNotifier].
  ///
  /// Returns true if it has attached the [changeNotifier] else false.
  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  bool hasAttachedChangeNotifier(ChangeNotifier changeNotifier) => _isNotDisposed?hasListener(changeNotifier.notifyListeners):null;

  /// Tries to start listening to the passed [changeNotifier].
  ///
  /// Starts listening to the notification events of the passed [changeNotifier] and returns true,
  /// if it wasn't previously listening to it or else just returns false.
  ///
  /// Note: A [ValueNotifier] is also a [ChangeNotifier].
  bool startListeningToChangeNotifier(ChangeNotifier changeNotifier){
    assert(changeNotifier!=null,"Could not start listening to a null.");
    if(_isNotDisposed){
      try {
        changeNotifier.addListener(this);
        return true;
      } catch(e) { return false; }
    }
    return null;
  }

  /// Tries to stop listening to the [changeNotifier] it was previously listening to.
  ///
  /// Note: A [ValueNotifier] is also a [ChangeNotifier].
  bool stopListeningToChangeNotifier(ChangeNotifier changeNotifier) {
    assert(changeNotifier!=null,"Could not start listening to a null.");
    if(_isNotDisposed){
      try {
        changeNotifier.removeListener(this);
        return true;
      } catch(e) { return false; }
    }
    return null;
  }

  /// Attach a Stream to this [Notifier]. Do not use this if your [Stream] is actually expecting some
  /// value apart from null!
  bool attachStream(StreamController s) => _isNotDisposed&&s!=null?addListener(s.add)!=null:null;

  /// Detach a Stream that was previously attached to this [Notifier] using [attachStream].
  bool detachStream(StreamController s) => _isNotDisposed&&s!=null?removeListener(s.add):null;

  /// Checks if the Notifier has attached the Stream
  bool hasAttachedStream(StreamController s) => _isNotDisposed&&s!=null?_hasListener(s.add):null;

  /// Makes the [Notifier] listen to an existing [stream]. In order to control or stop listening to
  /// this connection, you'll need to store the [StreamSubscription] returned by this function and use
  /// it as per your requirements.
  StreamSubscription listenTo(Stream stream) => stream?.listen(this);

  /// Asynchronously notify the listeners without blocking the
  Future<Notifier> asyncNotify([dynamic _]) async => Future(()=>call(_));

  /// Attaches the passed [notifier] to the current [Notifier]. The current [Notifier] will notify the attached [notifier]
  /// whenever it receives a notification. In order to [attach] multiple notifiers to the current [Notifier] use
  /// [attachAll]. The notifier will remained attached as long as it exists as one of the current [Notifier]'s listeners.
  bool attach(Notifier notifier) {
    assert(notifier != null, "You are trying to attach null to Notifier#$hashCode.\n");
    assert(notifier != this, "Please make sure that you don't attach the Notifier to itself, as it would lead to an Stack Overflow error whenever the Notifier gets notified.\n");
    assert(!this.isListeningTo(notifier), "Cross-attaching two notifiers is highly not recommended as it would lead to an endless cycle of notifier calls between the two notifiers until a Stack Overflow Error is finally thrown by the VM.\n\nYou could either merge() the two notifiers to create a new notifier that holds the listeners of both the notifiers (you'll have to maintain the newly created notifier separately)\n\nor\n\nIf you want to notify both/all the Notifiers while separately maintaining them create a List of them then notify that list as per your requirements.\n");
    return _attach(notifier);
  }

  bool _attach(Notifier notifier) =>
      (notifier == null) ? false : (addListener(notifier.notify) != null);

  /// Attaches the passed notifier or [notifiers] to the current [Notifier]. The current [Notifier] will notify
  /// all the attached [notifiers] whenever it receives a notification. By calling [clearListeners] you will
  /// automatically [detach] all the attached [notifiers] and [_listeners].
  Iterable<bool> attachAll(Iterable<Notifier> notifiers) {
    assert(notifiers != null,
        "You are trying to attach null to Notifier#$hashCode.");
    assert(!notifiers.containsEitherComp(this),
        "\nPlease make sure that you don't attach the Notifier to itself, as it would lead to an Stack Overflow error whenever the Notifier gets notified.\n");
    assert(!notifiers.hasListener(_notify).orAll(), """
        Cross-attaching multiple Notifier is highly not recommended as it would lead to endless cycle of notification 
        between the two Notifiers until a Stack Overflow error is finally yield.\n
        You could either merge the two Notifiers to create a new Notifier that holds the listeners of both the notifiers 
        and then use that 
        or
        If you want to notify both/all the Notifiers while seperately maintaining them create a list of them then notify \
        that list as per your requirements.""");
    return _attachAll(notifiers);
  }

  Iterable<bool> _attachAll(Iterable<Notifier> notifiers) => (notifiers == null)
      ? null
      : addListeners(notifiers._notify).map((e) => e != null);

  /// Checks if the passed [notifier] is attached to this [Notifier].
  ///
  /// If it is attached to the passed [notifier] it returns true else false.
  bool hasAttached(Notifier notifier) =>
      _isNotDisposed ? _hasAttached(notifier) : null;

  bool _hasAttached(Notifier notifier) => _listeners.containsEitherComp(notifier);

  /// Checks if the passed [notifiers] are attached to this [Notifier] and returns an [Iterable]
  /// <[bool]>.
  ///
  /// This method is basically performs [hasAttached] for multiple notifiers.
  Iterable<bool> hasAttachedThese(Iterable<Notifier> notifiers) =>
      _isNotDisposed ? _hasAttachedThese(notifiers) : null;

  Iterable<bool> _hasAttachedThese(Iterable<Notifier> notifiers) =>
      notifiers?.map(_hasAttached)?.toList();

  /// Checks if the passed [notifiers] have been attached to this [Notifier] and only return true
  /// if all of them have been attached.
  bool hasAttachedAll(Iterable<Notifier> notifiers) =>
      _isNotDisposed ? _hasAttachedAll(notifiers) : null;

  bool _hasAttachedAll(Iterable<Notifier> notifiers) {
    for (Notifier notifier in notifiers)
      if (!_hasAttached(notifier)) return false;
    return true;
  }

  /// Tries to detach the passed [notifier] from the current [Notifier].
  ///
  /// If it was previously attached, it detaches it and returns true else just returns false.
  bool detach(Notifier notifier) => _isNotDisposed ? _detach(notifier) : null;

  bool _detach(Notifier notifier) =>
      (notifier == null) ? null : removeListener(notifier);

  /// Tries to detach the passed [notifiers] from the current [Notifier].
  ///
  /// This method basically performs [detach] on multiple [notifiers] and returns all their return
  /// values as an [Iterable]<[bool]>.
  Iterable<bool> detachAll(Iterable<Notifier> notifiers) =>
      _isNotDisposed ? _detachAll(notifiers) : null;

  Iterable<bool> _detachAll(Iterable<Notifier> notifiers) =>
      removeListeners(notifiers?._notify);

  /// Starts listening to the given [notifier].
  ///
  /// Starts listening to the [notifier] and returns true if it was not previously listening to
  /// that [notifier] else just returns false.
  bool startListeningTo(Notifier notifier) {
    assert(notifier != null, "$runtimeType#$hashCode: A notifier cannot start listening to null.");
    assert(this != notifier, "$runtimeType#$hashCode: A notifier cannot start listening to itself.");
    return _startListeningTo(notifier);
  }

  bool _startListeningTo(Notifier notifier) => notifier?.attach(this);

  /// Tries to start listening to all the given [notifiers] and returns an [Iterable]<[bool]>.
  ///
  /// This method is basically an extension of [startListeningTo] that performs the same operation
  /// on multiple [notifiers].
  Iterable<bool> startListeningToAll(Iterable<Notifier> notifiers) =>
      _isNotDisposed ? _startListeningToAll(notifiers) : null;

  Iterable<bool> _startListeningToAll(Iterable<Notifier> notifiers) =>
      notifiers?.attach(notifiers);

  /// Stops listening to [notifier] passed to it.
  ///
  /// If it was previously listening to it, it stops listening to it and returns true else just
  /// returns false.
  bool stopListeningTo(Notifier notifier) =>
      _isNotDisposed ? _stopListeningTo(notifier) : null;

  bool _stopListeningTo(Notifier notifier) => notifier?._detach(this);

  /// Tries to stop listening to all the given [notifiers] and returns an [Iterable]<[bool]> based
  /// on it.
  ///
  /// This method is basically an extension of [stopListeningTo] that performs the same operation
  /// on multiple [notifiers].
  Iterable<bool> stopListeningToAll(Iterable<Notifier> notifiers) =>
      _isNotDisposed ? _stopListeningToAll(notifiers) : null;

  Iterable<bool> _stopListeningToAll(Iterable<Notifier> notifiers) => notifiers?.detach(this);

  /// Checks if the current [Notifier] is listening to the passed [notifier].
  ///
  /// If it is listening to it, it returns true else false.
  bool isListeningTo(Notifier notifier) =>
      _isNotDisposed ? _isListeningTo(notifier) : null;

  bool _isListeningTo(Notifier notifier) =>
      notifier?._hasAttached(this);

  /// Checks if the current [Notifier] is listening to the passed [notifiers].
  ///
  /// For every given index, if the current [Notifier] is listening to that notifier it sets true
  /// else false and finally returns the Iterable that was finally created.
  Iterable<bool> isListeningToAll(Iterable<Notifier> notifiers) =>
      notifiers?.hasAttached(this);

  /// This method can be used to re-init a disposed [Notifier], once it's disposed. However, it is
  /// highly recommended that you dispose the [Notifier] only once you are done with it. This
  /// method/concept was only introduced with the intenion of creating a reusable logic while
  /// developing a plugin.
  ///
  /// A Notifier that has been re-init is as good as a new Notifier apart from the fact that it is
  /// the same instance as the old one.
  ///
  /// If the [Notifier] has not been disposed or is not in disposed state it returns false else it
  /// re-init s the current [Notifier] and returns true.
  bool init({
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Function,dynamic) removeListenerOnError,
  }) {
    if (isDisposed && _init()) {
      if (mergeNotifiers != null) _addListeners(mergeNotifiers._listeners);
      if (attachNotifiers != null) _attach(attachNotifiers);
      if (listenToNotifiers != null) _startListeningTo(listenToNotifiers);
      this.._handleError = removeListenerOnError;
      return true;
    }
    return false;
  }

  bool _init() => (_listeners = []).isEmpty;

  static bool initNotifier(Notifier notifier) => notifier?.init();

  static Iterable<bool> initNotifiers(Iterable<Notifier> notifiers) =>
      notifiers?.init();

  /// Disposes the current [Notifier].
  ///
  /// If it has already been disposed it returns false else it disposes the [Notifier] and returns
  /// true.
  bool dispose() {
    if (isNotDisposed) {
      _dispose();
      return true;
    }
    return false;
  }

  _dispose() => _listeners = null;

  static bool disposeNotifier(Notifier notifier) => notifier?.dispose();
  static Iterable<bool> disposeNotifiers(Iterable<Notifier> notifiers) => notifiers?.dispose();

  /// Adds a listener to the [Notifier] and returns the listener's [hashCode] if successfully added else returns [null].
  ///
  /// The [hashCode] can then be used to uniquely [notify] the listener using the [notifyListener] method.
  ///
  /// Only a function that accepts no parameters or the one that accepts a single parameter can be
  /// added to this [Notifier].
  ///
  /// If the current [Notifier] already contains the given listener or if null is passed as a
  /// listener, it returns false else true.
  int addListener(Function listener) => _isNotDisposed && !_listeners.containsEitherComp(listener)
      ? _addListener(listener) : null;

  int _addListener(Function listener) {
    if (listener == null) return null;
    assert(listener is Function() || listener is Function(dynamic),
        "Notifier#$hashCode: A Notifier can only notify a listener that does not accept a parameter or accepts a 'single' parameter.");
    // ignore: unrelated_type_equality_checks
    if (this == listener)
      throw ArgumentError("Notifier#$hashCode: A notifier cannot listen to itself.");
    try {
      _listeners.add(listener);
    }catch(e){
      if(e is UnsupportedError) throw StateError("Notifier#$hashCode: The listeners have been currently locked from any modifications.\n\nPlease try calling unlockListeners() on me, before trying to (in)directly add a listener next time.");
      rethrow; // for any other unexpected error
    }
    return listener.hashCode;
  }


  static Map<Notifier, Iterable<int>> customListenerAdder(Map<Iterable<Notifier>, Function> options) =>
      options.map((notifiers, listener) =>
          MapEntry(notifiers, notifiers.addListener(listener)));

  Iterable<int> addListeners(Iterable<Function> listeners) =>
      _isNotDisposed ? _addListeners(listeners) : null;

  Iterable<int> _addListeners(Iterable<Function> listeners) =>
      listeners?.map(_addListener)?.toList();

  static Iterable<int> addListenersToNotifier(
          Notifier notifier, Iterable<Function> listeners) =>
      notifier?.addListeners(listeners);

  static Iterable<int> addListenersToNotifiers(
          Iterable<Notifier> notifiers, Iterable<Function> listeners) =>
      notifiers
          ?.map((notifier) => notifier.addListeners(listeners).elementAt(0))
          ?.toList();

  static Map<Notifier, Iterable<Iterable<int>>> customListenersAdder(Map<Iterable<Notifier>, Iterable<Function>> options) =>
      options.map((notifier, listeners) => MapEntry(notifier, notifier.addListeners(listeners)));

  /// Checks if the current [Notifier] has the passed [listener]. If it has it, it returns [true], else [false].
  bool hasListener(Function listener) =>
      _isNotDisposed && _hasListener(listener);

  bool _hasListener(Function listener) => _listeners.containsEitherComp(listener);

  /// Checks if the current [Notifier] has any listeners.
  ///
  /// If it has any, the method returns [true] else false.
  bool get hasListeners => _isNotDisposed && _hasListeners;
  bool get _hasListeners => _listeners.isNotEmpty;

  /// Checks if the current [Notifier] has at least any one of the given [listeners].
  ///
  /// Returns [true] if it finds it else [false].
  bool hasAnyListener(Iterable<Function> listeners) => _isNotDisposed ? _hasAnyListener(listeners) : null;

  bool _hasAnyListener(Iterable<Function> listeners) {
    for (Function listener in listeners)
      if (_listeners.containsEitherComp(listener)) return true;
    return false;
  }

  /// Checks if the current [Notifier] has all of the given [listeners].
  ///
  /// Returns [true] if it finds all else [false].
  bool hasAllListeners(Iterable<Function> listeners) => _isNotDisposed ? _hasAllListeners(listeners) : null;

  bool _hasAllListeners(Iterable<Function> listeners) {
    for (Function listener in listeners)
      if (!_listeners.containsEitherComp(listener)) return false;
    return true;
  }

  void _call(Function listener) => listener is Function() ? listener() : listener(null);

  /// Calls/notifies the listeners of the current Notifier
  ///
  /// The value passed to the parameter [_] is not received by the listeners.
  ///
  /// If the current [Notifier] is not disposed it return itself else null.
  Notifier call([dynamic _]) {
    if (_isNotDisposed) {
      for (int i = 0; i < _listeners.length; i++) {
        try {
          _call(_listeners[i]);
        } catch (e) {
          if (_handleError == null) rethrow;
          bool _ = _handleError(_listeners[i],e);
          if (_ == null) rethrow;
          if (_) {
            try {
              _listeners.removeAt(i--);
            } catch(e) {
              i++;
              if(e is UnsupportedError) throw StateError("ValNotifier#$hashCode: Could not remove ${_listeners[i]} as my listeners have been locked!\nPlease call unlockListeners() on me.");
              rethrow; // For any other unexpected error
            }
          }
        }
      }
      return this;
    }
    return null;
  }

  /// Calls the [Notifier] with the value that was stored in the buffer.
  Notifier operator ~() => notify();

  /// Helper getter that abstracts the call method for readability.
  Notifier get notify => this;

  /// Helper getter that abstracts the call method for readability.
  Notifier get notifyListeners => this;

  /// Helper getter that abstracts the call method for readability.
  Notifier get sendNotification => this;

  Function get _notify => this;

  /// A static function that notifies the [notifier] passed to it.
  static Notifier notifyNotifier(Notifier notifier) => ~notifier;

  /// A static function that notifies all the [notifiers] passed to it.
  static Iterable<Notifier> notifyAll(Iterable<Notifier> notifiers) =>
      notifiers?.map<Notifier>(notifyNotifier)?.toList();

  /// Tries to remove the passed [listener] if it is a listener of the current [Notifier].
  ///
  /// If the listener is a listener of the current [Notifier] and [isNotDisposed] then it returns [true] else false.
  bool removeListener(Function listener) =>
      _isNotDisposed ? _removeListener(listener) : null;

  bool _removeListener(Function listener){
    try{
      _listeners.remove(listener);
      return true;
    } catch(e){
      if(e is UnsupportedError) throw StateError("Notifier#$hashCode: The listeners have been currently locked from any modifications.\n\nPlease try calling unlockListeners() on me, before trying to (in)directly remove a listener next time.");
      rethrow; // For any unexpected error
    }
  }

  /// This function can be used to remove a specific listener by it's [hashCode], which can either be obtained as the
  /// return value of [addListener] or by manually storing the function as a variable and then obtaining it with the
  /// help of the getter hashCode. The return value determines if the transaction was successful or not.
  bool removeListenerByHashCode(int hashCode) => _isNotDisposed ? _removeListenerByHashCode(hashCode) : null;

  bool _removeListenerByHashCode(int hashCode) {
    try {
      return _listeners.remove(
          _listeners.firstWhere((listener) => listener.hashCode == hashCode));
    } catch (e) {
      if(e is UnsupportedError) throw StateError("Notifier#$hashCode: The listeners have been currently locked from any modifications.\n\nPlease try calling unlockListeners() on me, before trying to (in)directly remove a listener next time.");
      return false;
    }
  }

  /// An implementation of [removeListenerByHashCode] which deals with multiple [hashCodes]. Returns an [Iterable<bool>]
  /// based on the result of each transactions which equals the length of the passed list of [hashCodes].
  Iterable<bool> removeListenersByHashCodes(Iterable<int> hashCodes) =>
      _isNotDisposed ? hashCodes?.map(_removeListenerByHashCode)?.toList() : null;

  Iterable<bool> _removeListenersByHashCodes(Iterable<int> hashCodes) =>
      hashCodes?.map(_removeListenerByHashCode)?.toList();

  /// Tries to remove the list of passed [listeners] if the respective listener is a listener of the current [Notifier].
  ///
  /// It returns an Iterable<bool> values based on the state of each operation. Refer [removeListener] for more info.
  Iterable<bool> removeListeners(Iterable<Function> listeners) =>
      _isNotDisposed ? _removeListeners(listeners) : null;

  Iterable<bool> _removeListeners(Iterable<Function> listeners) =>
      listeners?.map(_removeListener);

  /// Tries to remove the passed [listener] if it is a listener of the passed [Notifier].
  ///
  /// A static implementation of [removeListener].
  static bool removeListenerFromNotifier(
          Notifier notifier, Function listener) =>
      notifier?.removeListener(listener);

  /// Tries to remove the list of passed [listeners] if the respective listener is a listener of the current [Notifier].
  ///
  /// A static implementation of [removeListeners].
  static Iterable<bool> removeListenerFromNotifiers(
          Iterable<Notifier> notifiers, Function listener) =>
      notifiers.removeListener(listener);

  /// Tries to remove the list of passed [listeners] if the respective listener is a part of the respective [Notifier]
  /// from the given list of [notifiers].
  ///
  /// A static implementation created by mapping [removeListeners] with each of those [notifiers].
  static Iterable<Iterable<bool>> removeListenersFromNotifiers(
          Iterable<Notifier> notifiers, Iterable<Function> listeners) =>
      notifiers?.removeListeners(listeners);

  /// Clears all the listeners of the current [Notifier]
  bool clearListeners() {
    _listeners?.clear();
    return _isNotDisposed;
  }

  /// Clears all the listeners of the given [Notifier].
  static bool clearListenersOfNotifier(Notifier notifier) =>
      notifier?.clearListeners();

  /// Clears all the listeners of the given list of [Notifier]s.
  static Iterable<bool> clearListenersOfNotifiers(
          Iterable<Notifier> notifiers) =>
      notifiers.clearListeners();

  /// Checks if the given [Notifier] is disposed or not. If disposed, returns [true] else returns [false].
  bool get isDisposed => _listeners == null;

  /// Checks if the given [Notifier] is disposed or not. If disposed, returns [false] else returns [true].
  bool get isNotDisposed => !isDisposed;

  /// Checks if the [Notifier] is not disposed while throwing an error if it's disposed.
  ///
  /// One could use [isNotDisposed] to check if a [Notifier] is disposed or not and then manually throw an error
  /// based on the developer's requirements/intuition.
  bool get _isNotDisposed {
    if (isDisposed)
      throw StateError('A $runtimeType was used after being disposed.\n'
          'Once you have called dispose() on a $runtimeType, you can use it by calling init() on it.\n'
          'However, it is recommended that you only dispose() the $runtimeType once you are done with it.\n');
    return isNotDisposed;
  }

  /// It is a special operator method that eases the process of creating dynamic UI and working with
  /// multiple notifiers.
  ///
  /// This method,
  ///
  /// * Returns null if null was passed.
  /// * Combines the two notifiers as a [Notifier], if a [Notifier]/[Iterable]<[Notifier]> was passed.
  /// * Returns a [NotificationBuilder] that just rebuilds when the [Notifier] is notified,
  /// if a method that accepts no parameters is passed.
  /// * Returns a [NotificationBuilder] that rebuilds while passing null, if a method that accepts
  /// a single parameter is passed.
  /// * Returns a [NotificationBuilder] that rebuilds while passing the [BuildContext] and value, if such a
  /// method is passed.
  operator -(_) {
    if (_ == null) return null;
    if (_ is Iterable<Notifier>) return merge(_);
    if (_ is Widget) return NotifiableChild(notifier: this, child: _);
    if (_ is Function(dynamic)) return SimpleNotificationBuilder(notifier: this, builder: _(null));
    if (_ is Function()) return SimpleNotificationBuilder(notifier: this, builder: (c) => _());
    if (_ is Function(BuildContext,dynamic)) return SimpleNotificationBuilder(notifier: this, builder: (c) => _(c,null));
    throw UnsupportedError(
        "Notifier#$hashCode: Notifier's operator - does not support ${_.runtimeType}.");
  }

  /// Creates a new instance of [Notifier] that holds the listeners of the current [Notifier] and the passed [notifier].
  Notifier operator +(Notifier notifier) =>
      _isNotDisposed ? (clone(this).._addListeners(notifier._listeners)) : null;

  /// Creates a new instance of [Notifier] that holds the listeners common to the current [Notifier] and passed [notifier].
  Notifier operator &(Iterable<Notifier> notifier) =>
      _isNotDisposed ? (clone(this).._addListeners(notifier._listeners)) : null;

  /// Creates a new instance of [Notifier] that holds the listeners of both the current [Notifier] and passed [notifier].
  Notifier operator |(Iterable<Notifier> notifier) =>
      clone(this)..removeListeners(notifier._listeners);

  /// Adds all the listeners of the passed [notifier] to the current [Notifier]
  Notifier operator <<(Iterable<Notifier> notifier) =>
      this..addListeners(notifier._listeners);

  /// Adds all the listeners of the current [Notifier] to the passed [notifier]
  Notifier operator >>(Iterable<Notifier> notifier) {
    notifier.addListeners(notifier._listeners);
    return this;
  }

  /// Reverse the order of all the _listeners.
  ///
  /// This would reverse the order in which every listener is notified.
  void reverseListeningOrder() => _listeners = _listeners.reversed.toList();

  /// Manually get a listener by it's index to perform any low-level operation with it.
  operator [](int index) => _isNotDisposed ? _listeners.elementAt(index) : null;

  /// Compares the current instance to the passed Object to check if the two are equal or not.
  ///
  /// If both the Notifier are the same instance or if the passed Function is actually the call method
  /// of that the Notifier, this operator returns true else false.
  /// (The call method was made equal to minimize the possibility of cross-attachment, however at the end
  /// not cross-attaching two notifiers is solely in the hands of the developer)
  bool operator ==(Object other) =>
      (other is Notifier || other is Notifier Function([dynamic])) &&
          (other.hashCode == hashCode);

  /// Returns the [hashCode] of the current [Notifier].
  int get hashCode => this.call.hashCode;

  /// Notifies a listener by it's [hashCode], which can be obtained by the return value of [addListener] or [addListeners]
  /// or by manually obtaining it by declaring a variable to hold that function and then later obtaining it's hashCode
  /// using the hashCode getter on that variable.
  ///
  /// If the passed [hashCode] doesn't match any of the listener's hashCode then the
  bool notifyByHashCode(int hashCode) =>
      _isNotDisposed ? _notifyByHashCode(hashCode) : null;

  bool _notifyByHashCode(int hashCode) {
    Function _ = _listeners.firstWhere(
        (listener) => listener.hashCode == hashCode,
        orElse: () => null);
    if (_ == null) return false;
    try{
      _ is Function() ? _() : _(null);
    } catch(e){
      debugPrint(
          "$runtimeType#${this.hashCode}: An error was thrown while specifically notifying the listener#$hashCode (String rep.:$_)");
      rethrow;
    }
    return true;
  }

  /// Notifies all the listeners whose [hashCodes] have been passed via this method.
  ///
  /// For any given index of the returned [Iterable], it sets false if the listener was not found
  /// else notifies that listener and sets true.
  Iterable<bool> notifyByHashCodes(Iterable<int> hashCodes) =>
      _isNotDisposed ? _notifyByHashCodes(hashCodes) : null;

  Iterable<bool> _notifyByHashCodes(Iterable<int> hashCodes) =>
      hashCodes?.map(_notifyByHashCode)?.toList();

  /// Returns the number of listeners of the current [Notifier] as [int] if it is not disposed.
  int get numberOfListeners => _isNotDisposed ? _listeners.length : null;

  /// Returns the string representation of an the current [Notifier].
  String toString() => "$runtimeType#$hashCode";

  /// Merges the passed set of [notifiers] into a single one.
  ///
  /// One can optionally set the [removeListenerOnError] parameter for the final returned [Notifier]
  static Notifier merge([Iterable<Notifier> notifiers, bool Function(Function, dynamic) removeListenerOnError]) =>
      notifiers == null ? Notifier._() : notifiers.merge(const [],removeListenerOnError);

  /// Returns a copy/clone of the passed [notifier].
  static Notifier from(Notifier notifier) {
    if (notifier.isDisposed)
      throw ArgumentError(
          """A disposed Notifier cannot be cloned!\nPlease make sure you clone it before disposing
           it, as a disposed Notifier loses track of it's listeners, once it's disposed.""");
    return Notifier(removeListenerOnError: notifier._handleError).._listeners = List.from(notifier._listeners);
  }

  static Notifier Function(Notifier) clone = from;

  /// Print this [Notifier]'s details in-line while testing with the help of (..) operator
  void get printMe => print(toString());

  /// Locks the listeners of the current [Notifier] and prevents anyone from adding/removing a
  /// listener from/to it (by any means).
  ///
  /// If the listeners are already locked, it returns false, else it locks the listeners and
  /// returns true.
  bool lockListeners(){
    if(_isNotDisposed) return _lockListeners();
    return null;
  }

  bool _lockListeners(){
    try {
      _listeners.add(null);
      _listeners.remove(null);
      _listeners = List.from(_listeners, growable: false);
      return true;
    } catch(e){ return false; }
  }

  /// Unlocks the listeners of the current [Notifier] and allows others to add a listener to it.
  ///
  /// If the listeners are already locked it returns false else it locks the listeners and
  /// returns true.
  bool unlockListeners(){
    if(_isNotDisposed) return _unlockListeners();
    return null;
  }

  bool _unlockListeners() {
    try {
      _listeners.add(null);
      _listeners.remove(null);
      return false;
    } catch(e) {
      _listeners = List.from(_listeners);
      return true;
    }
  }

  /// A getter method whose return value can determine whether the internal listeners of the current
  /// [Notifier] are locked from addition/removal or not.
  ///
  /// If it returns true it means they are locked else false.
  bool get listenersAreLocked {
    if(_isNotDisposed){
      try {
        _listeners.add(null);
        _listeners.remove(null);
        return false;
      } catch(e){return true;}
    }
    return null;
  }

  /// A getter method whose return value can determine whether the internal listeners of the current
  /// [Notifier] are free for addition/removal or not.
  ///
  /// If it returns true if they are unlocked else false.
  bool get listenersAreUnlocked => !listenersAreLocked;

  Iterator<Notifier> get iterator => {this}.iterator;

  /// Returns a clone of the internal list of listeners.
  ///
  /// Note: Modifying the returned [Iterable] would in no way affect the listeners that are being
  /// internally maintained.
  Iterable<Function> get listeners => List.from(_listeners);
}

extension IterableExtension on Iterable<bool> {
  bool andAll([int start = 0, int end]) {
    // Default values just in case the parameter contains null
    start ??= 0;
    end ??= length;
    assert(start >= 0 && end <= length);
    if (start < 0) start = 0;
    if (end > length) end = length;
    while (start != end) if (!this.elementAt(start++)) return false;
    return true;
  }

  bool orAll([int start, int end]) {
    assert((start ??= 0) >= 0 && (end ??= length - 1) < length);
    while (start != end) if (this.elementAt(start++)) return true;
    return false;
  }

  Iterable<bool> notAll([int start, int end]) => map((e) => !e).toList();

  bool hasNullValue([int start, int end]) {
    assert((start ??= 0) >= 0 && (end ??= length - 1) < length);
    while (start != end) if (this.elementAt(start) == null) return true;
    return false;
  }

  bool fillNullValuesWith([bool value = true, int start, int end]) {
    assert((start ??= 0) >= 0 && (end ??= length - 1) < length);
//    while (start != end)
    return false;
  }
}

//        StateError('A $runtimeType was used after being disposed.\n\n'
//        'Once you have called dispose() on a $runtimeType, you can use it by calling init() on it.\n\n'
//        'However, it is recommended that you only dispose() the $runtimeType once you are done with it.\n')
//    assert(!(this.hasAnyListener(attachments._notify).orAll()),
//    """
//        \nPlease make sure that you don't attach any Notifier to itself, as it would lead to a Stack Overflow error
//    whenever the Notifier gets notified.""");
//    assert(!(attachments.hasAnyListener(_notify).orAll()),
//    """
//        Cross-attaching multiple Notifier is highly not recommended as it would lead to endless cycle of notifications
//    between the two Notifiers until a Stack Overflow error is finally yield.\n
//    You could either merge the two Notifiers to create a new Notifier that holds the listeners of both the notifiers
//    or
//    Create a list of Notifiers that holds both the Notifier and then notify that list as per your requirements.""");
extension Iterable_Notifier on Iterable<Notifier> {
  Iterable<bool> init() => map(Notifier.initNotifier).toList();
  Iterable<bool> dispose() => map(Notifier.disposeNotifier).toList();
  Iterable<bool> hasListener(Function listener) =>
      map((notifier) => notifier?.hasListener(listener)).toList();
  Iterable<bool> hasAnyListener(Iterable<Function> listeners) =>
      map((notifier) => notifier.hasAnyListener(listeners)).toList();
  Iterable<bool> hasAllListeners(Iterable<Function> listeners) =>
      map((notifier) => notifier.hasAllListeners(listeners)).toList();
  Iterable<bool> attach(Iterable<Notifier> attachments) =>
      map((notifier) => notifier.attach(attachments)).toList();
  Iterable<Iterable<bool>> attachAll(Iterable<Notifier> notifiers) =>
      map((notifier) => notifier._attachAll(notifiers)).toList();
  Iterable<bool> hasAttached(Notifier notifier) =>
      map((n) => n?.hasAttached(notifier)).toList();
  Iterable<bool> hasAttachedAll(Iterable<Notifier> notifiers) =>
      map((n) => n?.hasAttachedAll(notifiers)).toList();
  Iterable<bool> detach(Notifier attachment) =>
      map((notifier) => notifier?.detach(attachment)).toList();
  Iterable<Iterable<bool>> detachAll(Iterable<Notifier> attachments) =>
      map((notifier) => notifier?.detachAll(attachments)).toList();
  Iterable<bool> startListeningTo(Notifier notifier) =>
      map((n) => notifier?.attach(n))?.toList();
  Iterable<Iterable<bool>> startListeningToAll(Iterable<Notifier> notifiers) =>
      notifiers?.map((n) => n?.attachAll(notifiers))?.toList();
  Iterable<bool> stopListeningTo(Notifier notifier) =>
      map((n) => notifier?.detach(n)).toList();
  Iterable<Iterable<bool>> stopListeningToAll(Iterable<Notifier> notifiers) =>
      notifiers?.detachAll(this);
  Iterable<bool> isListeningTo(Notifier notifier) =>
      map((n) => n?.isListeningTo(notifier));
  Iterable<bool> isListeningToAll(Iterable<Notifier> notifiers) =>
      map((n) => n?.isListeningTo(notifiers));
  Iterable<int> addListener(Function listener) =>
      map((notifier) => notifier?.addListener(listener)).toList();
  Iterable<Iterable<int>> addListeners(Iterable<Function> listeners) =>
      map((notifier) => notifier.addListeners(listeners)).toList();
  Iterable<bool> removeListener(Function listener) =>
      map((notifier) => notifier.removeListener(listener)).toList();
  Iterable<Iterable<bool>> removeListeners(Iterable<Function> listeners) =>
      map((n) => n?.removeListeners(listeners)).toList();
  Iterable<bool> notifyByHashCode(int hashCode) =>
      map((n) => n?.notifyByHashCode(hashCode)).toList();
  Iterable<Iterable<bool>> notifyByHashCodes(Iterable<int> hashCodes) =>
      map((n) => n?.notifyByHashCodes(hashCodes)).toList();
  Iterable<bool> removeListenerByHashCode(int hashCode) =>
      map((n) => n?.removeListenerByHashCode(hashCode)).toList();
  Iterable<Iterable<bool>> removeListenersByHashCodes(
          Iterable<int> hashCodes) =>
      map((n) => n?.removeListenersByHashCodes(hashCodes)).toList();
  Iterable<bool> clearListeners() => map((n) => n?.clearListeners()).toList();

  Iterable<bool> lockListeners() => map((n)=>n?.lockListeners()).toList();
  Iterable<bool> unlockListeners() => map((n)=>n?.lockListeners()).toList();

  Iterable<bool> hasListenerAtomic(Function listener) =>
      _atomicTest("hasListener")
          ? map((n) => n?._hasListener(listener)).toList()
          : null;
  Iterable<bool> hasAnyListenerAtomic(Iterable<Function> listeners) =>
      _atomicTest("hasAnyListener")
          ? map((n) => n._hasAnyListener(listeners)).toList()
          : null;
  Iterable<bool> hasAllListenersAtomic(Iterable<Function> listeners) =>
      _atomicTest("hasAllListeners")
          ? map((n) => n._hasAllListeners(listeners)).toList()
          : null;
  Iterable<bool> attachAtomic(Iterable<Notifier> attachments) =>
      _atomicTest("attach")
          ? map((notifier) => notifier?._attach(attachments)).toList()
          : null;
  Iterable<Iterable<bool>> attachAllAtomic(Iterable<Notifier> notifiers) =>
      _atomicTest("attachAll")
          ? map((notifier) => notifier._attachAll(notifiers)).toList()
          : null;
  Iterable<bool> hasAttachedAtomic(Notifier notifier) =>
      _atomicTest("hasAttached")
          ? map((n) => n._hasAttached(notifier)).toList()
          : null;
  Iterable<bool> hasAttachedAllAtomic(Iterable<Notifier> notifiers) =>
      _atomicTest("hasAttachedAll")
          ? map((n) => n._hasAttachedAll(notifiers)).toList()
          : null;
  Iterable<bool> detachAtomic(Notifier attachment) =>
      _atomicTest("detach") ? map((n) => n._detach(attachment)).toList() : null;
  Iterable<Iterable<bool>> detachAllAtomic(Iterable<Notifier> attachments) =>
      _atomicTest("detachAll")
          ? map((notifier) => notifier?._detachAll(attachments)).toList()
          : null;
  Iterable<bool> startListeningToAtomic(Notifier notifier) =>
      _atomicTest("startListeningTo")
          ? map((n) => notifier._attach(n))?.toList()
          : null;
  Iterable<Iterable<bool>> startListeningToAllAtomic(
          Iterable<Notifier> notifiers) =>
      _atomicTest("startListeningToAll")
          ? notifiers?.map((n) => n._attachAll(notifiers))?.toList()
          : null;
  Iterable<bool> stopListeningToAtomic(Notifier notifier) =>
      _atomicTest("stopListeningTo") ? map((n) => n._detach(n)).toList() : null;
  Iterable<bool> stopListeningToAllAtomic(Iterable<Notifier> notifiers) =>
      _atomicTest("stopListeningToAll")
          ? map((n) => n._stopListeningTo(n)).toList()
          : null;
  Iterable<bool> isListeningToAtomic(Notifier notifier) =>
      _atomicTest("isListeningTo")
          ? map((n) => n._isListeningTo(notifier))
          : null;
  Iterable<bool> isListeningToAllAtomic(Iterable<Notifier> notifiers) =>
      _atomicTest("isListeningToAll")
          ? map((n) => n._isListeningTo(notifiers))
          : null;
  Iterable<int> addListenerAtomic(Function listener) =>
      _atomicTest("addListener")
          ? map((n) => n._addListener(listener)).toList()
          : null;
  Iterable<Iterable<int>> addListenersAtomic(Iterable<Function> listeners) =>
      _atomicTest("addListeners")
          ? map((n) => n._addListeners(listeners).toList())
          : null;
  Iterable<bool> removeListenerAtomic(Function listener) =>
      _atomicTest("removeListener")
          ? map((n) => n._removeListener(listener)).toList()
          : null;
  Iterable<Iterable<bool>> removeListenersAtomic(
          Iterable<Function> listeners) =>
      _atomicTest("removeListeners")
          ? map((n) => n._removeListeners(listeners)).toList()
          : null;
  Iterable<bool> notifyByHashCodeAtomic(int hashCode) =>
      _atomicTest("notifyByHashCode")
          ? map((n) => n._notifyByHashCode(hashCode)).toList()
          : null;
  Iterable<Iterable<bool>> notifyByHashCodesAtomic(Iterable<int> hashCodes) =>
      _atomicTest("notifyByHashCodes")
          ? map((n) => n._notifyByHashCodes(hashCodes)).toList()
          : null;
  Iterable<bool> removeListenerByHashCodeAtomic(int hashCode) =>
      _atomicTest("removeListenerByHashCode")
          ? map((n) => n._removeListenerByHashCode(hashCode)).toList()
          : null;
  Iterable<Iterable<bool>> removeListenersByHashCodesAtomic(
          Iterable<int> hashCodes) =>
      _atomicTest("removeListenersByHashCodes")
          ? map((n) => n._removeListenersByHashCodes(hashCodes)).toList()
          : null;
  void clearListenersAtomic() => _atomicTest("clearListeners")
      ? forEach((n) => n._listeners.clear())
      : null;
  bool _atomicTest(String _) {
    if (contains(null))
      throw "Could not atomically perform $_() as this Iterable<Notifier>#$hashCode contained atleast one null value.";
    if (isAnyDisposed)
      throw "Could not atomically perform $_() as this Iterable<Notifier>#$hashCode contains atleast one Notifier that was disposed.";
    return true;
  }

  Iterable<bool> isDisposed() => _isDisposed().toList();
  Iterable<bool> isNotDisposed() => _isDisposed().notAll();
  Iterable<bool> _isDisposed() => map((n) => n.isDisposed);
  bool get isAnyDisposed {
    for (Notifier notifier in this)
      if (notifier?.isDisposed ?? true) return true;
    return false;
  }

  bool get isAllNotDisposed => isAnyDisposed;
  bool get isAllDisposed => !isAnyDisposed;
  bool get isAnyNotDisposed => !isAnyDisposed;
  Iterable<Notifier> get unDisposedNotifiers => where((notifier) => notifier.isNotDisposed);

  Iterable<Notifier> get notify => this;
  Iterable<Function> get _notify => map((notifier) => notifier?.notify);

  void get printMe => print(toString());

  Iterable<bool> get listenersAreLocked => map((n)=>n?.listenersAreLocked).toList();
  Iterable<bool> get listenersAreUnlocked => map((n)=>n?.listenersAreUnlocked).toList();

  Notifier merge([Iterable<Notifier> notifiers, bool Function(Function, dynamic) removeListenerOnError]){
    assert(!notifiers.isAnyDisposed, "This method expects you to pass an Iterable of undisposed notifiers.");
    Notifier n = Notifier._();
    n._addListeners(_listeners);
    n._addListeners(notifiers._listeners);
    return n.._handleError=removeListenerOnError;
  }

  void reverseListeningOrder() => unDisposedNotifiers.forEach((n) => n?.reverseListeningOrder());
  void reverseListeningOrderOf(int index) => this.elementAt(index)?.reverseListeningOrder();
  Iterable<Notifier> clone() => map(Notifier.clone);

  Iterable<int> get numberOfListeners => map((n) => n.numberOfListeners).toList();

  int get totalNumberOfListeners {
    int totalNumberOfListeners = 0;
    forEach((notifier) => totalNumberOfListeners+=notifier.numberOfListeners);
    return totalNumberOfListeners;
  }

  Iterable<Function> get _listeners {
    final List<Function> result = [];
    forEach((notifier) => result.addAll(notifier._listeners));
    return result;
  }

  Iterable<Iterable<Function>> get listeners => map((n)=>n?.listeners).toList();

  Iterable<Function> get allListeners {
    final List<Function> result = [];
    forEach((notifier) => result.addAll(notifier.listeners));
    return result;
  }

  Iterable<Notifier> call([dynamic _, bool atomic = false]) =>
      atomic && !_atomicTest("call") ? null : Notifier.notifyAll(this);
  SimpleNotificationBuilder operator -(Widget Function() builder) =>
      SimpleNotificationBuilder(notifier: this, builder: (c) => builder());
  Iterable<Notifier> operator <<(Iterable<Notifier> notifiers) =>
      map((n) => n << notifiers).toList();
  Iterable<Notifier> operator >>(Iterable<Notifier> notifiers) =>
      map((n) => n >> notifiers).toList();
}

class ValNotifier<T> extends Notifier
{
  T _val;

  ValNotifier({
    T initialVal,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Function,dynamic) removeListenerOnError,
  }) : _val=initialVal, super(attachNotifiers: attachNotifiers,
            listenToNotifiers: listenToNotifiers,
            mergeNotifiers: mergeNotifiers,
            initialListeners: initialListeners,
            removeListenerOnError: removeListenerOnError);

  ValNotifier._();

  T get val => _val;

  /// A method that can be used to load an async resource of type T and then pass it to the [ValNotifier]'s
  /// listeners if it's successfully retrieved else the error is either passed to the onError function
  Future<T> load(covariant Future<T> res, [Function onError]) => res.then((_)=>this(_)._val).catchError(onError??(){});

  /// The method [notifyAtInterval] notifies the current [ValNotifier] at the given/passed
  /// [interval].
  ///
  /// The notification that shall come at fixed interval can be be stopped by calling [Timer.cancel]
  /// on the [Timer] that's returned by this method.
  ///
  /// If null is explicitly passed to this method, it'll automatically get resolved to
  /// [Duration.zero].
  Timer notifyAtInterval(Duration interval) =>
      _isNotDisposed ? Timer.periodic(interval??Duration.zero, (timer)=>this(_val,false)) : null;

  static ValNotifier<T> merge<T>([Iterable<ValNotifier<T>> notifiers]) =>
      notifiers == null ? ValNotifier._() : notifiers.merge();

  bool canPerformThisTween(Tween<T> tween) {
    if(_isNotDisposed){
      if(tween==null||tween.end==null||tween.begin==null) return false;
      _canPerformThisTween(tween);
    }
    return null;
  }

  bool _canPerformThisTween(Tween<T> tween) {
    if(tween==null||tween.end==null||tween.begin==null) return false;
    try {
      tween.transform(0.5);
      return true;
    } catch (e) { return _transform(tween)!=null; }
  }

  Tween _transform(Tween tween) {

    switch(T) {
      case AlignmentGeometry: return AlignmentGeometryTween(begin: tween.begin, end: tween.end);
      case Alignment: return AlignmentTween(begin: tween.begin, end: tween.end);
      case BorderRadius: return BorderRadiusTween(begin: tween.begin, end: tween.end);
      case Border: return BorderTween(begin: tween.begin, end: tween.end);
      case BoxConstraints: return BoxConstraintsTween(begin: tween.begin, end: tween.end);
      case Color: return ColorTween(begin: tween.begin,end: tween.end);
      case Decoration: return DecorationTween(begin: tween.begin,end: tween.end);
      case EdgeInsetsGeometry: return EdgeInsetsGeometryTween(begin: tween.begin,end: tween.end);
      case EdgeInsets: return EdgeInsetsTween(begin: tween.begin,end: tween.end);
      case FractionalOffset: return FractionalOffsetTween(begin: tween.begin,end: tween.end);
      case int: return IntTween(begin: tween.begin,end: tween.end);
      case Offset: return MaterialPointArcTween(begin: tween.begin,end: tween.end);
      case Matrix4: return Matrix4Tween(begin: tween.begin,end: tween.end);
      case Rect: return RectTween(begin: tween.begin,end: tween.end);
      case RelativeRect: return RelativeRectTween(begin: tween.begin,end: tween.end);
      case ShapeBorder: return ShapeBorderTween(begin: tween.begin,end: tween.end);
      case Size: return SizeTween(begin: tween.begin,end: tween.end);
      case TextStyle: return TextStyleTween(begin: tween.begin,end: tween.end);
      case ThemeData: return ThemeDataTween(begin: tween.begin,end: tween.end);
    }

    return null;
  }


  Future<ValNotifier<T>> animate(T begin, T end, Duration duration, {int loop=1, bool reverse=false, Curve curve = Curves.linear}) {
    if(T==dynamic) debugPrint("Calling animate on a ValNotifier<dynamic> might be an bad idea.\n"
        "Please try being more specific by using the method performTween with the appropriate type.");
    // Error wasn't throw for the type dynamic since there is a very tiny possibility that someone might
    // declare an extension method on Tween<dynamic>.
    return performTween(Tween<T>(begin: begin, end: end), duration, loop: loop, reverse: reverse , curve: curve);
  }


  Future<ValNotifier<T>> circularAnimate(T begin, T end, Duration duration, {int circles=1, bool reverse=false, Curve firstCurve = Curves.linear, Curve secondCurve = Curves.linear}) {
    if(_isNotDisposed){
      if(T==dynamic) debugPrint("Calling circularAnimate on a ValNotifier<dynamic> might be an bad idea.\n"
          "Please try being more specific while specifying the type of variable that holds the ValNotifier().");
      // Error wasn't throw for the type dynamic since there is a very tiny possibility that someone might
      // declare an extension method on Tween<dynamic>.
      return performCircularTween(Tween<T>(begin: begin, end: end), duration, circles: circles, reverse: reverse , firstCurve: firstCurve, secondCurve: secondCurve);
    }
    return null;
  }

  /// The [performTween] method performs a Tween<[T]> given to given to it via the [tween] parameter
  /// over the given [duration] of time. Performing a tween, just means to pass a range of values to
  /// the listeners of this [ValNotifier]<[T]>, where each value is directly generated at run-time
  /// with the help of the [tween.transform] method that accepts a [double] between 0..1 and
  /// returns the expected value at that point of time. This class does have an internal function
  /// that transforms the [tween] to a method to the expected type based on the value of [T], but it
  /// surely has it's own limitation and cannot detect a custom class/type that was implemented by you.
  ///
  /// A short explanation of the other parameters supported by this method,
  ///
  /// * One can directly perform the same tween n number of times by using the passing the number of
  /// times the tween needs to be performed by the [loop] parameter (default: 1). Passing 0 will still
  /// perform a tween and for a negative number, it's absolute value shall be taken into consideration.
  ///
  /// * If you want to perform the tween in the reverse direction, pass true to the optional arguments
  /// [reverse] and the method will handle the rest for you. Passing any other value is equivalent of
  /// performing in [forward] direction. (default: true/null -> forward)
  ///
  /// * The animation of the Tween can be performed in a specific [curve], by passing that [Curve] to
  /// the [curve] parameter of this [ValNotifier]<[T]> (default: [Curves.linear])
  ///
  /// If you have encountered the [UnsupportedError] then please consider using/implementing a custom
  /// that (in)directly extends the [Tween]<[T]> class and has properly implemented the transform method
  /// in the expected way.
  ///
  /// A [ValNotifier]<[T]> by default, is not capable of controlling a animation that is being
  /// performed on it and is actually unaware of it. If you want to control the animation that is being
  /// performed by the [ValNotifier]<[T]> then please consider using a [TweenNotifier]<[T]> instead.
  Future<ValNotifier<T>> performTween(Tween<T> tween, Duration duration, {int loop=1, bool reverse=false, Curve curve = Curves.linear}) async {

    if(_isNotDisposed) {

      assert(tween != null,
      "$runtimeType#$hashCode: Make sure that you pass a non-null value to the tween parameter of performTween([...]) method.");
      assert(
      tween.begin != null && tween.end != null,
      "$runtimeType#$hashCode: Cannot performTween([...]) through null values. tween.begin or tween.end was initialized to null\n"
          "Use the notifyNull");
      assert(duration != null && duration != Duration.zero,
      "The performTween() method needs a valid duration to perform a Tween.");
      assert(curve != null,
      "The parameter curve of performTween method just received null.\nThe default value of curve is Curves.linear.\n"
          "Passing value to curve parameter is not necessary.");

      try{
        tween.transform(0.5);
      } catch(e){
        tween = _transform(tween);
        if(tween==null) throw UnsupportedError("The $runtimeType#$hashCode could not perform the tween $tween. Make sure you use/implement an custom class that extends Tween<$T> and has overriden the transform method in an expected manner. The plugin has added support to directly convert a raw Tween instance to an appropriate one (if supported by the SDK), but it unfortunately couldn't find one for the current type $T. If you have implemented a custom class from your end then please directly use that instead of relying on a raw class.");
      }

      return _performTween(tween, duration, loop: loop, reverse: reverse, curve: curve).then((t){
        t.dispose();
        return this;
      });
    }

    return null;
  }

  Future<Ticker> _performTween(Tween<T> tween, Duration duration, {int loop=1, bool reverse=false, Curve curve = Curves.linear, Ticker t}) async {

    T _;
    reverse??=false;

    if(t==null){
      if(reverse){
        _ = tween.end;
        tween.end = tween.begin;
        tween.begin = _;
        reverse = null;
      }
      t = Ticker((d) {
        if (d > duration) {
          call(tween.begin);
          return t..stop();
        }
        return call(tween.transform(1 - curve.transform(d.inMilliseconds / duration.inMilliseconds)));
      });
    }

    loop = _times(loop);
    while(loop--!=0) await t.start();
    if(reverse==null){
      tween.begin = tween.end;
      tween.end = _;
    }
    return t;
  }

  /// The [performCircularTween] method performs the [tween] passed to it in a circular manner over the
  /// given [duration] (something like [tween.begin]...[tween.end]...[tween.begin]). The values
  /// are obtained with the help of the [tween.transform] method. The first half of the circular
  /// animation can be performed with a different [firstCurve] and the second half with a different one.
  /// [secondCurve]. By default, they both are [Curves.linear].
  ///
  /// A short explanation of the parameters supported,
  ///
  /// * The named parameter [circles] can be used to perform the the same tween in a circular manner for
  /// more than once. If it receives a negative value, it's absolute value is taken into consideration
  /// and it is guaranteed to perform the tween in a circular once, even if it receives 0 or null.
  ///
  /// * The named parameter [reverse] can be used to perform the [tween] in the reverse direction
  /// (something like [tween.end]...[tween.begin]...[tween.end]). Giving it any other value or not
  /// giving it any value will (in)directly tell the method to perform the [tween] in the default
  /// forward direction.
  ///
  /// * The named parameter [firstCurve] can be used to modify the way the animation is played in the
  /// first half (default: [Curves.linear]). However, it must be noted that this wouldn't affect the way the second
  /// half of the animation is played ([secondCurve]).
  ///
  /// * The named parameter [secondCurve] can be used to modify the way the animation is played in the
  /// second half (while returning) (default: [Curves.linear]). The [firstCurve] will still remain
  /// unchanged unless a value was specified for it.
  ///
  /// A [ValNotifier]<[T]> by default, is not capable of controlling a animation that is being
  /// performed on it and is actually unaware of it. If you want to control the animation that is being
  /// performed by the [ValNotifier]<[T]> then please consider using a [TweenNotifier]<[T]> instead.
  Future<ValNotifier<T>> performCircularTween(Tween<T> tween, Duration duration, {int circles=1, bool reverse=false, Curve firstCurve = Curves.linear, Curve secondCurve = Curves.linear}) async {

    if(_isNotDisposed){
      assert(tween != null,
      "$runtimeType#$hashCode: Make sure that you pass a non-null value to the tween parameter of performTween([...]) method.");
      assert(
      tween.begin != null && tween.end != null,
      "$runtimeType#$hashCode: Cannot performTween([...]) through null values. tween.begin or tween.end was initialized to null\n"
          "Use the notifyNull");
      assert(duration != null && duration != Duration.zero,
      "The performTween() method needs a valid duration to perform a Tween.");
      assert(firstCurve != null,
      "The parameter firstCurve of performTween method just received null.\nThe default value of curve is Curves.linear.\n"
          "Passing value to curve parameter is not necessary.");
      assert(secondCurve != null,
      "The parameter secondCurve of performTween method just received null.\nThe default value of curve is Curves.linear.\n"
          "Passing value to curve parameter is not necessary.");

      try{
        tween.transform(0.5);
      } catch(e){
        tween = _transform(tween);
        if(tween==null) throw UnsupportedError("The $runtimeType#$hashCode could not perform the tween $tween. Make sure you use an custom class that extends Tween<$T> and has overriden the transform method in an expected manner. The plugin has added support to directly convert a raw Tween instance to an appropriate one (if supported by the SDK), but it unfortunately couldn't find one for the current type $T. If you have implemented a custom class from your end then please");
      }

      reverse??=false;
      circles=_times(circles);
      duration~/=2;

      Ticker t1,t2;
      T _;

      if(reverse){
        _ = tween.end;
        tween.end = tween.begin;
        tween.begin = _;
        reverse = null;
      }

      t1 = Ticker((d) {
        if (d > duration) {
          call(tween.end);
          return t1..stop();
        }
        return call(tween.transform(firstCurve.transform(d.inMilliseconds / duration.inMilliseconds)));
      });

      t2 = Ticker((d) {
        if (d > duration) {
          call(tween.begin);
          return t2..stop();
        }
        return call(tween.transform(1 - secondCurve.transform(d.inMilliseconds / duration.inMilliseconds)));
      });


      return Future.doWhile(() async {
        await _performTween(tween, duration, t: t1);
        await _performTween(tween, duration, t: t2);
        return --circles!=0;
      }).then((_){
        t1.dispose();
        t2.dispose();
        if(reverse==null){
          tween.begin = tween.end;
          tween.end = _;
        }

        return this;
      });
    }
    return null;
  }

  int _times(int times) {
    if(times==null||times==0) return 1;
    return times.abs();
  }

  /// The method [interpolateR] can be used to interpolate across multiple [values] over a fixed period of time
  /// ([totalDuration]). This method interfaces the the method [interpolate] for types that are internally known by
  /// this class.
  ///
  /// A short description about the named parameters,
  ///
  /// * The named parameter [loop] can be used to perform the same interpolation multiple times (minimum: 1; assuming
  /// no assertion has failed or error has been thrown)
  ///
  /// * The named parameter [reverse] can be set to true to reverse the direction of interpolation, i.e. Iterable end
  /// to start. (default: false; start to end)
  ///
  /// * The named parameter [curve] can be used to specify a single [Curve] for all the transformations that occur
  /// during the interpolation. (default: [Curves.linear])
  ///
  /// * The named parameter [curves] can be used to specify the curve for each transformation taking place between each
  /// pair of values. All the empty space and null values are filled with the value of the parameter [curve]. However,
  /// if null values still found in the iterable, an assertion fails. To avoid that one can either give an expected
  /// value to the parameter [curve] or ensure that there is one curve for every transformation that takes place (pair
  /// of values, i.e. [values.length]-1)
  ///
  /// A animation animation/interpolation performed by a [ValNotifier] cannot be controlled in any way, once it starts.
  /// If you want to be control this interpolation, then please consider using a [TweenNotifier] instead. It performs
  /// only one animation at a time that can be controlled by the instance methods provided by it's class.
  Future<ValNotifier<T>> interpolateR(Iterable<T> values, Duration totalDuration, {int loop=1, bool reverse=false, Curve curve = Curves.linear, Iterable<Curve> curves}) async {
    if(_isNotDisposed) {
      if(T==dynamic) debugPrint("Calling interpolateR on a $runtimeType<dynamic> might be an bad idea.\n"
          "Please try being more specific while specifying the type of variable that holds the ValNotifier().");
      return interpolate(Tween<T>(),values, totalDuration, loop: loop, reverse: reverse, curve: curve, curves: curves);
    }
    return null;
  }

  /// The method [interpolate] can be used to interpolate across multiple [values] over a fixed duration
  /// ([totalDuration]). The [tween] that is passed to this method acts like a helper object whose
  /// transform method is used to calculate the value at a specific point. The [Duration] that is passed
  /// to this method's [totalDuration] parameter is the total duration over which the interpolation
  /// shall take place. One can either modify the curve in which each transformation shall take place
  /// through the [curves] parameter or pass a common [curve] for all (first preference shall always be
  /// given to the [curves] parameter).
  ///
  /// A short explanation for each named parameter,
  ///
  /// * The named parameter [loop] specifies the number of times the interpolation should take place in
  /// in total. Irrespective of the value passed, the method is guaranteed to interpolate for once.
  ///
  /// * The named parameter [reverse] specifies the direction in which the interpolation shall take
  /// place [A..B..C]/[C..B..A]. If set to true, the interpolation shall be performed in the reverse
  /// direction else in forward direction. (default: false/null -> forward)
  ///
  /// * The named parameter [curve] can be used to specify the curve in which all the transformations
  /// during this interpolation shall be performed.
  ///
  /// * The named parameter [curves] can be used to specify the curve in which each transformation of
  /// the interpolation shall take place. If the value at a specific index is null or if the number of
  /// curves are less than expected, then those places shall be filled with the value passed in curve
  /// (default [Curves.linear]). If that too is explicitly defined as null then an assertion shall fail.
  ///
  /// A [ValNotifier]<[T]> by default, is not capable of controlling a animation that is being
  /// performed on it and is actually unaware of it. If you want to control the animation that is being
  /// performed by the [ValNotifier]<[T]> then please consider using a [TweenNotifier]<[T]> instead.
  Future<ValNotifier<T>> interpolate(Tween<T> tween, Iterable<T> values, Duration totalDuration, {int loop=1, bool reverse=false, Curve curve = Curves.linear, Iterable<Curve> curves}) async {
    if(_isNotDisposed){

      List<Curve> _curves = curves?.toList();

      assert(tween!=null,"You cannot interpolate across values without a buffer Tween.");
      assert(values!=null,"The parameter values cannot be set to null.");
      assert(totalDuration!=null && totalDuration!=Duration.zero,"The total duration of the interpolation cannot be set to null.");
      assert(values.length>1,"We need at least two values to successfully interpolate.");
      if(curves==null) _curves = List.filled(values.length-1, curve);
      else {
        _curves = curves.map((e) => e ?? curve).toList();
        while(_curves.length<values.length) _curves.add(curve);
        _curves.removeLast();
        assert(!_curves.contains(null),"Please pass some value to the curve parameter in order to fill the null(s) in the passed curves Iterable with it or please fix it, if it was unexpected.");
      }
      assert(_curves.length+1==values.length,"Please make sure that you have a curve for each transformation and not each value. There were ${curves.length-values.length+1} more curves than expected.");

      try{
        tween.transform(0.5);
      } catch(e){
        tween = _transform(tween);
        if(tween==null) throw UnsupportedError("The $runtimeType#$hashCode could not perform the tween $tween. Make sure you use an custom class that extends Tween<$T> and has overriden the transform method in an expected manner. The plugin has added support to directly convert a raw Tween instance to an appropriate one (if supported by the SDK), but it unfortunately couldn't find one for the current type $T. If you have implemented a custom class from your end then please");
      }

      loop = _times(loop);
      totalDuration~/=_curves.length;

      return _interpolate(tween, values, totalDuration, loop: loop, reverse: reverse, curves: _curves);
    }
    return null;
  }

  /// The method [circularInterpolationR] (R=raw) is a method that interfaces the method
  /// [circularInterpolation] for the tween types known by a ValNotifier ([_transform] method).
  /// It relies solely on the value of [T] to determine which type of tween the circular interpolation
  /// of the passed values can be performed using. If it doesn't find one, an [UnsupportedError] error
  /// is thrown with an appropriate message. That's the reason why using this method on a
  /// [ValNotifier]<[dynamic]> might be an bad idea.
  ///
  /// To know more about circular interpolation, please read the docs of the method
  /// [circularInterpolation].
  Future<ValNotifier<T>> circularInterpolationR(Iterable<T> values, Duration totalDuration, {int circles=1, Curve firstCurve=Curves.linear, Curve secondCurve=Curves.linear, Iterable<Curve> firstCurves, Iterable<Curve> secondCurves})
  {
    if(_isNotDisposed){
      assert(values!=null,"The parameter values cannot be set to null.");
      assert(values.length>1, "We need at least two values to successfully interpolate.");
      return circularInterpolation(_sTween(values), values, totalDuration, circles: circles, firstCurve: firstCurve, secondCurve: secondCurve, firstCurves: firstCurves, secondCurves: secondCurves);
    }
    return null;
  }

  // static final Map<Type,Tween Function(Tween)> _tweenMap = {
  //   AlignmentGeometry: (t)=>AlignmentGeometryTween(begin: t.begin ?? Alignment.center, end: t.end ?? Alignment.center),
  //   BorderRadius: (t)=> BorderRadiusTween(begin: t.begin ?? BorderRadius.zero, end: t.end ?? BorderRadius.zero),
  //   Border: (t)=> BorderTween(begin: t.begin ?? const Border(), end: t.end ?? const Border()),
  //   BoxConstraints: (t)=> BoxConstraintsTween(begin: t.begin ?? const BoxConstraints(), end: t.end ?? const BoxConstraints()),
  //   Color: (t)=> ColorTween(begin: t.begin ?? Colors.transparent, end: t.end ??  Colors.transparent),
  //   Decoration: (t)=> DecorationTween(begin: t.begin ?? const BoxDecoration(), end: t.end ?? const BoxDecoration()),
  //   EdgeInsetsGeometry: (t)=> EdgeInsetsGeometryTween(begin: t.begin ?? EdgeInsets.zero, end: t.end ?? EdgeInsets.zero),
  //   EdgeInsets: (t)=> EdgeInsetsTween(begin: t.begin ?? EdgeInsets.zero, end: t.end ?? EdgeInsets.zero),
  //   FractionalOffset: (t)=> FractionalOffsetTween(begin: t.begin ?? const FractionalOffset(0,0), end: t.end ?? const FractionalOffset(0,0)),
  //   int: (t)=> IntTween(begin: t.begin ?? 0, end: t.end ??  0),
  //   Offset: (t)=> MaterialPointArcTween(begin: t.begin ??  Offset.zero, end: t.end ?? Offset.zero),
  //   Matrix4: (t)=> Matrix4Tween(begin: t.begin ?? Matrix4.zero(), end: t.end ?? Matrix4.zero()),
  //   Rect: (t)=> RectTween(begin: t.begin ?? Rect.zero, end: t.end ?? Rect.zero),
  //   RelativeRect: (t)=> RelativeRectTween(begin: t.begin ?? RelativeRect.fill, end: t.end ?? RelativeRect.fill),
  //   ShapeBorder: (t)=> ShapeBorderTween(begin: t.begin ?? const Border(), end: t.end ?? const Border()),
  //   Size: (t)=> SizeTween(begin: t.begin ?? Size.zero, end: t.end ?? Size.zero),
  //   TextStyle: (t)=> TextStyleTween(begin: t.begin ?? const TextStyle(), end: t.end ?? const TextStyle()),
  //   ThemeData: (t)=> ThemeDataTween(begin: t.begin ?? ThemeData(), end: t.end ?? ThemeData()),
  // };

  Tween _sTween(Iterable<T> values) {
    if(values is Iterable<AlignmentGeometry>) return AlignmentGeometryTween(begin: Alignment.center, end: Alignment.center);
    if(values is Iterable<Alignment>) return AlignmentTween(begin: Alignment.center, end: Alignment.center);
    if(values is Iterable<BorderRadius>) return BorderRadiusTween(begin: BorderRadius.zero, end: BorderRadius.zero);
    if(values is Iterable<Border>) return BorderTween(begin: const Border(), end: const Border());
    if(values is Iterable<BoxConstraints>) return BoxConstraintsTween(begin: const BoxConstraints(), end: const BoxConstraints());
    if(values is Iterable<Color>) return ColorTween(begin: Colors.transparent, end: Colors.transparent);
    if(values is Iterable<Decoration>) return DecorationTween(begin: const BoxDecoration(), end: const BoxDecoration());
    if(values is Iterable<EdgeInsetsGeometry>) return EdgeInsetsGeometryTween(begin: EdgeInsets.zero, end: EdgeInsets.zero);
    if(values is Iterable<EdgeInsets>) return EdgeInsetsTween(begin: EdgeInsets.zero, end: EdgeInsets.zero);
    if(values is Iterable<FractionalOffset>) return FractionalOffsetTween(begin: const FractionalOffset(0,0), end: const FractionalOffset(0,0));
    if(values is Iterable<int>) return IntTween(begin: 0, end: 0);
    if(values is Iterable<Offset>) return MaterialPointArcTween(begin: Offset.zero, end: Offset.zero);
    if(values is Iterable<Matrix4>) return Matrix4Tween(begin: Matrix4.zero(), end: Matrix4.zero());
    if(values is Iterable<Rect>) return RectTween(begin: Rect.zero, end: Rect.zero);
    if(values is Iterable<RelativeRect>) return RelativeRectTween(begin: RelativeRect.fill, end: RelativeRect.fill);
    if(values is Iterable<ShapeBorder>) return ShapeBorderTween(begin: const Border(), end: const Border());
    if(values is Iterable<Size>) return SizeTween(begin: Size.zero, end: Size.zero);
    if(values is Iterable<TextStyle>) return TextStyleTween(begin: const TextStyle(), end: const TextStyle());
    if(values is Iterable<ThemeData>) return ThemeDataTween(begin: ThemeData(), end: ThemeData());
    return _transform(Tween<T>());
  }

  /// The [circularInterpolation] method perform an interpolation in a circular manner over a fixed
  /// duration of time ([totalDuration]) across the specified [values]. Something like A..B..C..B..A
  /// instead of just A..B..C (normal interpolation). The [tween] that is passed just acts as an helper
  /// object whose transform method is used to get the value between two consequent transformation
  /// (during the interpolation).
  ///
  /// A short explanation of all the named parameters,
  ///
  /// * The named parameter [circles] decides the number of times the circular interpolation should
  /// take place. It is guaranteed to take place for at least once, irrespective of the value passed to
  /// this parameter.
  ///
  /// * The named parameter [firstCurve] decides how the each transformation should take place for the
  /// first half of the interpolation. (default: [Curves.linear])
  ///
  /// * The named parameter [secondCurve] decides how the each transformation should take place for the
  /// second half of the interpolation. (default: [Curves.linear])
  ///
  /// * The named parameter [firstCurves] if passed a non-null value, decides how each transformation
  /// should take place for the first half of the interpolation. If the passed [Iterable] is shorter
  /// than the expected length or if null is found in it, the iterable shall get filled with
  /// [firstCurve] values to meet the expected requirement. If null is still found in the passed
  /// iterable or if it's longer than that, then an assertion fails.
  ///
  /// * The named parameter [secondCurves] if passed a non-null value, decides how each transformation
  /// should take place for the second half of the interpolation. If the passed [Iterable] is shorter
  /// than the expected length or if null is found in it at any index, the [Iterable] shall then get
  /// filled with [secondCurve] values to meet the expected requirement. If null is still found in the
  /// passed iterable since [secondCurve] could have been null or if it's longer than that, the
  /// expected length an assertion fails.
  Future<ValNotifier<T>> circularInterpolation(Tween<T> tween, Iterable<T> values, Duration totalDuration, {int circles=1, Curve firstCurve=Curves.linear, Curve secondCurve=Curves.linear, Iterable<Curve> firstCurves, Iterable<Curve> secondCurves})
  {

    if(_isNotDisposed) {

      assert(tween!=null,"You cannot interpolate across values without a buffer Tween.");
      assert(values!=null,"The parameter values cannot be set to null.");
      assert(totalDuration!=null && totalDuration!=Duration.zero,"The total duration of the interpolation cannot be set to null.");
      assert(values.length>1, "We need at least two values to successfully interpolate.");

      assert(!(firstCurves==null&&firstCurve==null), "Please ensure that either firstCurve or firstCurves is not null.");
      assert(!(secondCurves==null&&secondCurve==null), "Please ensure that either secondCurve or secondCurves is not null.");

      List<Curve> _firstCurves = firstCurves?.toList(), _secondCurves = secondCurves?.toList();

      if(firstCurves==null) _firstCurves = List.filled(values.length-1, firstCurve);
      else {
        assert(firstCurves.length<values.length,"Please make sure that there is a (first)Curve for every interpolation and not every value. The firstCurves iterable had ${firstCurves.length-values.length} more curves than expected!");
        _firstCurves = firstCurves.map((e) => e ?? firstCurve).toList();
        while(_firstCurves.length<values.length) _firstCurves.add(firstCurve);
        _firstCurves.removeLast();
        assert(!_firstCurves.contains(null),"Please pass some value to the firstCurve parameter in order to fill the null(s) in the passed firstCurve Iterable with it or please fix it, if it was unexpected.");
      }

      if(secondCurves==null) _secondCurves = List.filled(values.length-1, secondCurve);
      else {
        assert(secondCurves.length<values.length,"Please make sure that there is a (first)Curve for every interpolation and not every value. The firstCurves iterable had ${secondCurves.length-values.length} more curves than expected!");
        _secondCurves = secondCurves.map((e) => e ?? secondCurve).toList();
        while(_secondCurves.length<values.length) _secondCurves.add(secondCurve);
        _secondCurves.removeLast();
        assert(!_secondCurves.contains(null),"Please pass some value to the secondCurve parameter in order to fill the null(s) in the passed curves secondCurve with it or please fix it, if it was unexpected.");
      }

      try{
        tween.transform(0.5);
      } catch(e){
        tween = _transform(tween);
        if(tween==null) throw UnsupportedError("The $runtimeType#$hashCode could not perform the tween $tween. Make sure you use an custom class that extends Tween<$T> and has overriden the transform method in an expected manner. The plugin has added support to directly convert a raw Tween instance to an appropriate one (if supported by the SDK), but it unfortunately couldn't find one for the current type $T. If you have implemented a custom class from your end then please");
      }

      List<T> _values = []..addAll(values)..removeLast()..addAll(values.toList().reversed);
      List<Curve> _curves = []..addAll(_firstCurves)..addAll(_secondCurves);

      circles = _times(circles);
      totalDuration~/=_curves.length;

      return Future.doWhile(() async {
        await _interpolate(tween, _values, totalDuration, curves: _curves);
        return --circles!=0;
      }).then((value) => this);
    }
    return null;
  }

  Future<ValNotifier<T>> _interpolate(Tween<T> tween, Iterable<T> values, Duration duration, {int loop=1, bool reverse=false, Iterable<Curve> curves, Ticker t}) async {

      Curve curve;

      if(reverse??=false) {
        values = values.toList().reversed;
        curves = curves.toList().reversed;
      }

      int i;

      t = Ticker((d) async {
        if (d > duration) {
          call(tween.end);
          return t..stop();
        }
        return call(tween.transform(curve.transform(d.inMilliseconds / duration.inMilliseconds)));
      });

      tween.end=values.first;
      return Future.doWhile(() async {
        i = 1;
        do {
          tween.begin = tween.end;
          tween.end = values[i];
          curve = curves[i-1];
          await t.start();
        } while(++i!=values.length);
        return --loop!=0;
      }).then((_){
        t.dispose();
        return this;
      });
  }

  /// The [performTweens] method is just a helper method for the [performTween] method that can perform
  /// multiple [tweens] with the same setting(/parameter) for multiple number of times.
  ///
  /// Note: The [duration] that is passed to this method is not the total duration, but the duration
  /// for each tween shall animate.
  ///
  /// A short explanation for the named parameters supported by this method,
  ///
  /// * The named parameter [loop] specifies the number of times for which all the [tweens] shall be
  /// performed. Each loop performs, the entire set once. (A..B..A..B and not A..A..B..B). One set of
  /// [tweens] is guaranteed to be performed once irrespective of the value passed to this parameter.
  ///
  /// * The named parameter [reverse] if set to true performs the each tween in reverse direction at
  /// an individual level. If you want to perform the entire set in the reverse direction (from end to
  /// start) then please use the getter reversed on the [List] you were suppose to pass. If it isn't a
  /// [List] but is a [Iterable] then please consider using the instance method toList() on to obtain
  /// a list.
  ///
  /// * The named parameter [curve] can be used to modify the way each tween in [tweens] is played.
  ///
  /// This method was made with the intention of performing multiple tweens with the same setting.
  /// If your requirements wish you to perform multiple tweens with different settings, then please
  /// consider using [performTween] while awaiting each of them in an async to keep them in sync.
  Future<ValNotifier<T>> performTweens(Iterable<Tween<T>> tweens, Duration duration, {int loop=1,bool reverse=false, Curve curve = Curves.linear}) async {
    if(_isNotDisposed){
      assert(tweens != null,
      "$runtimeType#$hashCode: You passed null value to the tweens parameter of the performTweens([...]) method.");
      assert(duration != null && duration != Duration.zero,
      "The performTween() method needs a valid duration to perform a Tween.");
      assert(curve != null,
      "The parameter curve of performTween method just received null.\nThe default value of curve is Curves.linear.\n"
          "Passing value to curve parameter is not necessary.");

      tweens = tweens.map((tween){
        try {
          tween.transform(0.5);
        } catch(e) {
          tween = _transform(tween);
          if(tween==null) throw UnsupportedError("The $runtimeType#$hashCode cannot not perform the tween $tween. Make sure you use an custom class that extends Tween<$T> and has overriden the transform method in an expected manner. The plugin has added support to directly convert a raw Tween instance to an appropriate one (if supported by the SDK), but it unfortunately couldn't find one for the current type $T. If you have implemented a custom class from your end then please ensure that you pass it's instance as a Tween.");
        }
        return tween;
      });

      reverse??=false;

      Iterable<Ticker> iT = tweens.map((tween){
        Ticker t;
        return t = reverse ? Ticker((d) {
          if (d > duration) {
            call(tween.begin);
            return t..stop();
          }
          return call(tween.transform(1 - curve.transform(d.inMilliseconds / duration.inMilliseconds)));
        }) : Ticker((d) {
          if (d > duration) {
            call(tween.end);
            return t..stop();
          }
          return call(tween.transform(curve.transform(d.inMilliseconds / duration.inMilliseconds)));
        });
      });

      loop=_times(loop);

      while(loop--!=0)
        for(Ticker t in iT)
          await _performTween(null, duration, loop: loop, reverse: reverse, curve: curve, t: t);
      return this;
    }
    return null;
  }

  @override
  bool _notifyByHashCode(int hashCode) {
    Function _ = _listeners.firstWhere(
            (listener) => listener.hashCode == hashCode,
        orElse: () => null);
    if (_ == null) return false;
    try{
      _ is Function() ? _() : _(val);
    } catch(e){
      debugPrint("Notifier#${this.hashCode}: An error was thrown while specifically notifying the listener#$hashCode (String rep.:$_)");
      rethrow;
    }
    return true;
  }

  /// A method that overloads the operator() to enable the developer to directly call a [ValNotifier]<T>
  /// to notify it's listeners. If the parameter [val] gets a non-null value of type T, it notifies all
  /// the listeners with that value and if the [save] parameter receives true, it stores the value in the
  /// internal buffer of this [ValNotifier]<T>. On the other hand if the parameter [val] receives null,
  /// or if a value isn't passed to it (since it's a optional argument), it'll notify the listeners with
  /// the value that was previously saved (default: null).
  ///
  /// If you want to clear the value stored internally in the buffer, then please consider using the
  /// instance method [nullNotify] instead.
  ValNotifier<T> call([covariant T val, bool save = true]) {
    if (val == null) val = this._val;
    if (_isNotDisposed) {
      for (int i = 0; i < _listeners.length; i++) {
        try {
          _listeners[i] is Function(T) ? _listeners[i](val) : _listeners[i]();
        } catch (e) {
          if (_handleError == null) rethrow;
          bool _ = _handleError(_listeners[i],e);
          if (_ == null) rethrow;
          if (_) {
            try {
              _listeners.removeAt(i--);
            } catch(e) {
              i++;
              if(e is UnsupportedError) throw StateError("ValNotifier#$hashCode: Could not remove ${_listeners[i]} as my listeners had been locked!\nPlease call unlockListeners() on me.");
              rethrow; // For any other unexpected error
            }
          }
        }
      }
      if (save==true) _val = val;
      return this;
    }
    return null;
  }

  /// Attach a Stream to this [ValNotifier] to get notified, whenever it gets called.
  bool attachStream(covariant StreamController<T> s) => _isNotDisposed?addListener(s.add)!=null:null;

  /// Detach a Stream that was previously attached to this [ValNotifier] via [attachStream] method.
  bool detachStream(covariant StreamController<T> s) => _isNotDisposed?removeListener(s.add):null;

  /// Makes the [ValNotifier] listen to an existing stream. Use the [StreamSubscription] returned from
  /// this method control or cancel this connection.
  StreamSubscription<T> listenTo(covariant Stream<T> stream) => stream.listen(this);

  /// Notifies null to all the listeners and clears the value stored in the ValNotifier's buffer.
  ///
  /// Trying to do this by any other means, would be as good as not passing any value to that function.
  /// i.e. The previous value shall get notified again.
  ValNotifier<T> nullNotify() => this(_val = null);

  // Other ways to call the current [ValNotifier]
  // Getters were used instead of methods to minimize the chance of accidental cross-attachment
  // of two or more notifiers and to reduce the complexity of the code that detects.

  /// Calls the [ValNotifier] with the value that was stored in the buffer.
  ValNotifier<T> operator ~() => notify();

  /// Helper getter that abstracts the call method for readability.
  ValNotifier<T> get notify => super.notify;

  /// Helper getter that abstracts the call method for readability.
  ValNotifier<T> get notifyListeners => super.notifyListeners;

  /// Helper getter that abstracts the call method for readability.
  ValNotifier<T> get sendNotification => super.sendNotification;

  /// It is a special operator method that eases the process of creating dynamic UI and working with
  /// multiple notifiers.
  ///
  /// This method,
  ///
  /// * Returns null if null was passed.
  /// * Combines the two [ValNotifier] as a [ValNotifier], if a [ValNotifier] was passed.
  /// * Combines the two [Notifier]s as a [Notifier], if a [Notifier] was passed
  /// * Returns a [NotificationBuilder] that just rebuilds when the ValNotifier is notified,
  /// if a method that accepts no parameters is passed.
  /// * Returns a [NotificationBuilder] that rebuilds while passing the value, if a method that accepts
  /// a single parameter (of the current type [T]) or something that has a wider scope (including this type)
  /// else an [UnsupportedError] shall been thrown.
  /// * Returns a [NotificationBuilder] that rebuilds while passing the [BuildContext] and value, if such a
  /// method is passed. If the two types differ in any way or are not within the scope of expected types
  /// an [UnsupportedError] shall been thrown.
  operator -(_) {
    if(_ == null) return null;
    if (_ is ValNotifier<T>) return ValNotifier.merge<T>([this, _]);
    if (_ is Iterable<Notifier>) return merge(_);
    if (_ is Function()) return NotificationBuilder(notifier: this, builder: (c) => _());
    if (_ is Function(T)) return NotificationBuilder(notifier: this, builder: (c) => _(_val));
    if (_ is Function(BuildContext, T)) return NotificationBuilder(notifier: this, builder: (c) => _(c, _val));
    if (_ is Widget) return NotifiableChild(notifier: this, child: _);
    throw UnsupportedError("$runtimeType<$T>#$hashCode: $runtimeType<$T>'s operator - does not support ${_.runtimeType}.");
  }


  /// The method [init] can be used to re-init a disposed [ValNotifier]<[T]>.
  ///
  /// It re-init's the disposed Notifier and returns true, if it was previously disposed.
  ///
  /// else it just returns false.
  bool init({
    T initialVal,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Function,dynamic) removeListenerOnError,
  }){
    if(isDisposed){
      _val = initialVal;
      super.init(attachNotifiers: attachNotifiers, listenToNotifiers: listenToNotifiers, mergeNotifiers: mergeNotifiers, initialListeners: initialListeners, removeListenerOnError: removeListenerOnError);
      return true;
    }
    return false;
  }

  void _dispose() {
    super._dispose();
    _val = null;
  }
}

enum HttpRequestType { GET, HEAD, DELETE, READ, READBYTES, POST, PUT, PATCH }

class HttpNotifier extends ValNotifier {

  /// A single client for all http requests
  http.Client _client;

  /// A buffer that stores the URL (for sync)
  String _url;

  String get url => _isNotDisposed ? _url : null;
  set url(String url) {
    if (_isNotDisposed) {
      assert(url != null, "$runtimeType#$hashCode could not set the url to null.");
      // Regex Source: https://stackoverflow.com/a/55674757
      assert(RegExp(r"(https?|http)://([-A-Z0-9.]+)(/[-A-Z0-9+&@#/%=~_|!:,.;]*)?(\?[A-Z0-9+&@#/%=~_|!:‌​,.;]*)?", caseSensitive: false).hasMatch(url), "Please make sure that you set $runtimeType#$hashCode with a valid url. Don't forget to add (http/https):// at the start of the url (as per your use case).");
      _url = url;
    }
  }

  /// A buffer that stores the headers (for sync)
  Map<String, String> _headers;

  set headers(Map<String, String> headers){
    if(_isNotDisposed){
      _headers = headers;
    }
  }
  get headers => _isNotDisposed?_headers:null;

  /// A buffer that stores the request type (for sync)
  HttpRequestType _requestType;

  HttpRequestType get requestType => _isNotDisposed ? _requestType : null;
  set requestType(HttpRequestType requestType) {
    if (_isNotDisposed) {
      assert(requestType != null, "$runtimeType#$hashCode cannot set requestType to null");
      _requestType = requestType;

    }
  }

  /// A buffer that stores the body (for sync)
  String _body;

  get body {
    if(_isNotDisposed){
      if(HttpRequestType.values.indexOf(requestType) <= 4) throw "$runtimeType#$hashCode's requestType ($requestType) doesn't allow it to hold a body.\n\nPlease try setting the requestType of the $runtimeType to something that actually supports sending a body as the request.\n";
      return _body;
    }
  }
  set body(dynamic body) {
    if (_isNotDisposed) {
      if(HttpRequestType.values.indexOf(requestType) <= 4) throw "$runtimeType#$hashCode's requestType ($requestType) doesn't allow it to hold a body.\n\nPlease either set the requestType of the $runtimeType to something that actually supports sending a body as the request.";
      if (body != null && (body is String || body is Map<String, dynamic>)) throw Exception("$runtimeType#$hashCode could not set the body to a custom object.\n\nPlease either pass a String or a Map<String, dynamic> to the method setBody. If you meant to pass the String representation of the object then please directly pass it using toString().");
      if (body is Map<String, dynamic>) body = json.encode(body);
      _body = body;
    }
  }

  /// A buffer that stores the encoding (for sync)
  Encoding _encoding;

  get encoding {
    if(_isNotDisposed){
      if(HttpRequestType.values.indexOf(requestType) <= 4) throw "$runtimeType#$hashCode has not been set to a type that requires a body. Therefore the body couldn't be retrieved.\n";
      return _encoding;
    }
  }
  set encoding(Encoding encoding) {
    if(_isNotDisposed){
      if(HttpRequestType.values.indexOf(requestType) <= 4) throw "$runtimeType#$hashCode's requestType ($requestType) doesn't allow it to hold a body that could be 'encoded' in a specific way.\n\nPlease either set the requestType of the $runtimeType to something that could actually support it.";
      _encoding = encoding;
    }
  }

  /// A function that can transform the return value of an HTTP request into something that your listeners might
  /// actually need or be designed for.
  dynamic Function(dynamic) _parseResponse;

  get parseResponse => _isNotDisposed?_parseResponse:null;
  set parseResponse(Function(dynamic) parseResponse) => _isNotDisposed?_parseResponse = parseResponse:null;

  bool _isLoading = false;

  bool get isLoading => _isNotDisposed?(_isLoading==true):null;
  bool get isIdle    => _isNotDisposed?!isLoading:null;
  bool get hadError  => _isNotDisposed?_isLoading==null:null;

  HttpNotifier({
    @required String url,
    HttpRequestType requestType,
    Map<String, String> headers,
    String body,
    Encoding encoding,
    dynamic initialVal,
    bool syncOnCreate=true,
    Function(dynamic) parseResponse,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Function,dynamic) removeListenerOnError,
  })  : assert(url != null, "A $runtimeType cannot be created without an URL. Please make sure that you provide a valid url."),
        // Regex Source: https://stackoverflow.com/a/55674757
        assert(RegExp(r"(https?|http)://([-A-Z0-9.]+)(/[-A-Z0-9+&@#/%=~_|!:,.;]*)?(\?[A-Z0-9+&@#/%=~_|!:‌​,.;]*)?", caseSensitive: false).hasMatch(url), "Please make sure that you init $runtimeType#$hashCode with a valid url. Don't forget to add (http/https):// at the start of the url (as per your use case)."),
        assert(requestType == null || ((HttpRequestType.values.indexOf(requestType) <= 4) == (body == null && encoding == null)), "Please make sure that you only pass a body when the request type is capable of sending one!"),
        _url=url,
        _headers=headers,
        _body=body,
        _requestType = requestType,
        _encoding=encoding,
        _parseResponse=parseResponse,
        _client = http.Client(),
        super(attachNotifiers: attachNotifiers, initialVal: initialVal, listenToNotifiers: listenToNotifiers, mergeNotifiers: mergeNotifiers, initialListeners: initialListeners, removeListenerOnError: removeListenerOnError)
  {
      if (_requestType == null) {
        debugPrint("Could not find detect a requestType for $runtimeType#$hashCode");
        _requestType = (body == null && encoding == null)?HttpRequestType.GET:HttpRequestType.POST;
        debugPrint("Resolving the default type of $runtimeType#$hashCode to $_requestType");
      }
      if(syncOnCreate) sync();
  }

  factory HttpNotifier.get({
    @required String url,
    Map<String, String> headers,
    dynamic initialVal,
    Function(dynamic) parseResponse,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Error) removeListenerOnError,
  }) =>
      HttpNotifier(
          url: url,
          initialVal: initialVal,
          requestType: HttpRequestType.GET,
          parseResponse: parseResponse,
          headers: headers,
          attachNotifiers: attachNotifiers,
          listenToNotifiers: listenToNotifiers,
          mergeNotifiers: mergeNotifiers,
          initialListeners: initialListeners);

  factory HttpNotifier.head({
    @required String url,
    Map<String, String> headers,
    dynamic initialVal,
    Function(dynamic) parseResponse,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Error) removeListenerOnError,
  }) =>
      HttpNotifier(
          url: url,
          initialVal: initialVal,
          requestType: HttpRequestType.HEAD,
          parseResponse: parseResponse,
          headers: headers,
          attachNotifiers: attachNotifiers,
          listenToNotifiers: listenToNotifiers,
          mergeNotifiers: mergeNotifiers,
          initialListeners: initialListeners);

  factory HttpNotifier.delete({
    @required String url,
    Map<String, String> headers,
    dynamic initialVal,
    Function(dynamic) parseResponse,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Error) removeListenerOnError,
  }) =>
      HttpNotifier(
          url: url,
          requestType: HttpRequestType.DELETE,
          headers: headers,
          initialVal: initialVal,
          parseResponse: parseResponse,
          attachNotifiers: attachNotifiers,
          listenToNotifiers: listenToNotifiers,
          mergeNotifiers: mergeNotifiers,
          initialListeners: initialListeners);

  factory HttpNotifier.read({
    @required String url,
    Map<String, String> headers,
    dynamic initialVal,
    Function(dynamic) parseResponse,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Error) removeListenerOnError,
  }) =>
      HttpNotifier(
          url: url,
          initialVal: initialVal,
          requestType: HttpRequestType.READ,
          headers: headers,
          parseResponse: parseResponse,
          attachNotifiers: attachNotifiers,
          listenToNotifiers: listenToNotifiers,
          mergeNotifiers: mergeNotifiers,
          initialListeners: initialListeners);

  factory HttpNotifier.readBytes({
    @required String url,
    Map<String, String> headers,
    dynamic initialVal,
    Function(dynamic) parseResponse,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Error) removeListenerOnError,
  }) =>
      HttpNotifier(
          url: url,
          requestType: HttpRequestType.READBYTES,
          parseResponse: parseResponse,
          initialVal: initialVal,
          headers: headers,
          attachNotifiers: attachNotifiers,
          listenToNotifiers: listenToNotifiers,
          mergeNotifiers: mergeNotifiers,
          initialListeners: initialListeners);

  factory HttpNotifier.post({
    @required String url,
    Map<String, String> headers,
    dynamic body,
    Encoding encoding,
    Function(dynamic) parseResponse,
    dynamic initialVal,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Error) removeListenerOnError,
  }) =>
      HttpNotifier(
          url: url,
          requestType: HttpRequestType.POST,
          initialVal: initialVal,
          headers: headers,
          parseResponse: parseResponse,
          body: body,
          encoding: encoding,
          attachNotifiers: attachNotifiers,
          listenToNotifiers: listenToNotifiers,
          mergeNotifiers: mergeNotifiers,
          initialListeners: initialListeners);

  factory HttpNotifier.put({
    @required String url,
    Map<String, String> headers,
    dynamic body,
    Encoding encoding,
    Function(dynamic) parseResponse,
    dynamic initialVal,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Error) removeListenerOnError,
  }) =>
      HttpNotifier(
          url: url,
          requestType: HttpRequestType.PUT,
          headers: headers,
          body: body,
          encoding: encoding,
          parseResponse: parseResponse,
          initialVal: initialVal,
          attachNotifiers: attachNotifiers,
          listenToNotifiers: listenToNotifiers,
          mergeNotifiers: mergeNotifiers,
          initialListeners: initialListeners);

  factory HttpNotifier.patch({
    @required String url,
    Map<String, String> headers,
    dynamic body,
    Encoding encoding,
    Function(dynamic) parseResponse,
    dynamic initialVal,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Error) removeListenerOnError,
  }) =>
      HttpNotifier(
          url: url,
          requestType: HttpRequestType.PATCH,
          headers: headers,
          body: body,
          encoding: encoding,
          parseResponse: parseResponse,
          attachNotifiers: attachNotifiers,
          listenToNotifiers: listenToNotifiers,
          mergeNotifiers: mergeNotifiers,
          initialListeners: initialListeners);

  bool init({
    @required String url,
    HttpRequestType requestType,
    Map<String, String> headers,
    String body,
    Encoding encoding,
    Function(dynamic) parseResponse,
    dynamic initialVal,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Function,dynamic) removeListenerOnError,
  }) {
    if(isDisposed) {
      assert(url != null, "A $runtimeType cannot be init without an URL. Please make sure that you provide a valid url.");
      // Regex Source: https://stackoverflow.com/a/55674757
      assert(RegExp(r"(https?|http)://([-A-Z0-9.]+)(/[-A-Z0-9+&@#/%=~_|!:,.;]*)?(\?[A-Z0-9+&@#/%=~_|!:‌​,.;]*)?", caseSensitive: false).hasMatch(url), "Please make sure that you init $runtimeType#$hashCode with a valid url. Don't forget to add (http/https):// at the start of the url (as per your use case).");
      if (requestType != null) assert((HttpRequestType.values.indexOf(requestType) <= 4) == (body == null && encoding == null), "Please make sure that you only pass a body when the request type is capable of sending one!");

      if (super.init(
        initialVal: initialVal,
        attachNotifiers: attachNotifiers,
        listenToNotifiers: listenToNotifiers,
        mergeNotifiers: mergeNotifiers,
        initialListeners: initialListeners,
        removeListenerOnError: removeListenerOnError))
      {
        _url = url;
        _headers = headers;
        _body = body;
        _requestType = requestType;
        _encoding = encoding;
        this.parseResponse = parseResponse;
        if (_requestType == null) {
          debugPrint("Could not find detect a requestType for $runtimeType#$hashCode...");
          _requestType = (body == null && encoding == null)?HttpRequestType.GET:HttpRequestType.POST;
          debugPrint("Resolving the default type of $runtimeType#$hashCode to $_requestType");
        }
        _client = http.Client();
        return true;
      } else return false;
    }
    return false;
  }

  void _dispose() {
    super._dispose();
    _client.close();
    _client = null;
    _body = null;
    _headers = null;
    _url = null;
    _encoding = null;
    _requestType = null;
    _isLoading = null;
  }

  get({String url, Map<String, String> headers, bool saveResponse = true, bool saveParams = false, Function(dynamic) parseResponse,}) =>
      sync(
          url: url,
          parseResponse: parseResponse,
          requestType: HttpRequestType.GET,
          headers: headers,
          saveResponse: saveResponse,
          saveParams: saveParams);
  head({String url, Map<String, String> headers, bool saveResponse = true, bool saveParams = false, Function(dynamic) parseResponse}) =>
      sync(
          url: url,
          requestType: HttpRequestType.HEAD,
          parseResponse: parseResponse,
          headers: headers,
          saveResponse: saveResponse,
          saveParams: saveParams);
  delete(
          {String url,
          Map<String, String> headers,
          Function(dynamic) parseResponse,
          bool saveResponse = true,
          bool saveParams = false}) =>
      sync(
          url: url,
          headers: headers,
          requestType: HttpRequestType.DELETE,
          saveResponse: saveResponse,
          saveParams: saveParams);

  read({String url,
          Map<String, String> headers,
          Function(dynamic) parseResponse,
          bool saveResponse = true,
          bool saveParams = false}) =>
      sync(
          url: url,
          headers: headers,
          parseResponse: parseResponse,
          requestType: HttpRequestType.READ,
          saveResponse: saveResponse,
          saveParams: saveParams);

  readBytes(
          {String url,
          Map<String, String> headers,
          Function(dynamic) parseResponse,
          bool saveResponse = true,
          bool saveParams = false}) =>
      sync(
          url: url,
          headers: headers,
          parseResponse: parseResponse,
          requestType: HttpRequestType.READBYTES,
          saveResponse: saveResponse,
          saveParams: saveParams);

  post(
          {String url,
          Map<String, String> headers,
          dynamic body,
          Encoding encoding,
          Function(dynamic) parseResponse,
          bool saveResponse = true,
          bool saveParams = false}) =>
      sync(
          url: url,
          headers: headers,
          parseResponse: parseResponse,
          requestType: HttpRequestType.POST,
          saveResponse: saveResponse,
          saveParams: saveParams);
  put(
          {String url,
          Map<String, String> headers,
          dynamic body,
          Encoding encoding,
          Function(dynamic) parseResponse,
          bool saveResponse = true,
          bool saveParams = true}) =>
      sync(
          url: url,
          headers: headers,
          parseResponse: parseResponse,
          requestType: HttpRequestType.PUT,
          saveResponse: saveResponse,
          saveParams: saveParams);

  patch(
          {String url,
          Map<String, String> headers,
          dynamic body,
          Function(dynamic) parseResponse,
          Encoding encoding,
          bool saveResponse = true,
          bool saveParams = false}) =>
      sync(
          url: url,
          headers: headers,
          parseResponse: parseResponse,
          requestType: HttpRequestType.PATCH,
          saveResponse: saveResponse,
          saveParams: saveParams);


  Future sync({String url,
      Map<String, String> headers,
      HttpRequestType requestType,
      dynamic body,
      Encoding encoding,
      Function(dynamic) parseResponse,
      bool saveResponse = true,
      bool saveParams = true}) async {

    // Parameter validation
    if (requestType != null) assert((HttpRequestType.values.indexOf(requestType) <= 4) == (body == null && encoding == null), "Please make sure that you only pass a body when the request type is capable of sending one!");
    if (body != null) assert(body is String || body is Map<String, dynamic>, "$runtimeType#$hashCode could not set the body to a custom object.\n\nPlease either pass a String or a Map<String, dynamic> to the method setBody. If you meant to pass the String representation of the object then please directly pass it using toString().");
    if (url!=null&&!RegExp(r"(https?|http)://([-A-Z0-9.]+)(/[-A-Z0-9+&@#/%=~_|!:,.;]*)?(\?[A-Z0-9+&@#/%=~_|!:‌​,.;]*)?", caseSensitive: false).hasMatch(url)) throw Exception("Please make sure that you init $runtimeType#$hashCode with a valid url. Don't forget to add (http/https):// at the start of the url (as per your use case).");

    //
    if (requestType == null) requestType = this._requestType;
    if (url == null) url = this._url;
    if (headers == null) headers = this._headers;
    if (body == null) body = this._body;
    if (encoding == null) encoding = this._encoding;
    if(parseResponse==null) parseResponse = this.parseResponse;

    if (saveParams == true) {
      if(requestType!=null) this.requestType = requestType;
      if(url!=null) this.url = url;
      if(headers!=null) this.headers = headers;
      if(body!=null){
        if (body is Map<String, dynamic>) body = json.decode(body);
        this.body = body;
      }
      if(parseResponse!=null) this.parseResponse = parseResponse;
      if(encoding!=null) this.encoding = encoding;
    }

    dynamic r;
    _isLoading = true;
    call();

    try {
      switch (requestType) {
        case HttpRequestType.GET:
          r = await _client.get(url, headers: headers);
          break;
        case HttpRequestType.HEAD:
          r = await _client.head(url, headers: headers);
          break;
        case HttpRequestType.DELETE:
          r = await _client.delete(url, headers: headers);
          break;
        case HttpRequestType.READ:
          r = await _client.read(url, headers: headers);
          break;
        case HttpRequestType.READBYTES:
          r = await _client.readBytes(url, headers: headers);
          break;
        case HttpRequestType.POST:
          r = await _client.post(url, headers: headers, body: body, encoding: encoding);
          break;
        case HttpRequestType.PUT:
          r = await _client.put(url, headers: headers, body: body, encoding: encoding);
          break;
        case HttpRequestType.PATCH:
          r = await _client.patch(url, headers: headers, body: body, encoding: encoding);
          break;
      }

      try{call(parseResponse==null?r:parseResponse(r) ?? r, saveResponse == true);}catch(e){throw e;}
      _isLoading = false;
      return r;
    } catch (e) {
      _isLoading = null;
      call(parseResponse==null?e:parseResponse(e), saveResponse == true);
      return e;
    }
  }

  bool get hasData => _val != null && !(_val is Error);
  bool get hasError => _val != null && _val is Error;
  get data => hasData ? _val : null;
  get error => hasError ? _val : null;
}

class TickerNotifier extends Notifier
{
  Ticker _t;
  Duration _pD = Duration.zero;
  DateTime _pT;

  /// The [start] method can be used to start the default ticker of the current [TickerNotifier] if
  /// no other ticker operation like polling (or even the default operation) is going on.
  ///
  /// The parameter [play] in this context can be used to not play the ticker operation as soon as
  /// the ticker starts by passing false to it. Passing any other value (true/null) to this parameter
  /// will make it perform the default operation (play).
  ///
  /// It starts the default operation and returns true, if an operation was not previously active else
  /// just returns false.
  bool start({bool play=true}){
    if(_isNotDisposed){
      if(_t.isActive) return false;
      _t.start();
      _t.muted = play!=true;
      return true;
    }
    return null;
  }

  /// This is a simple method that interfaces the [start] and tries to start the ticker that could
  /// have been ticking after the given [duration] of time. It returns the return value returned by
  /// the [pause] method as a [Future]<[bool]>
  Future<bool> startAfter(Duration d) => _isNotDisposed ? Future.delayed(d,start) : null;

  /// The [play] method resumes the playing of an ticker operation that had been previously either
  /// stopped by the [pause] method or had been set to pause by default while starting it via
  /// the named parameter 'play' of the [start] method which could have implicitly done by the
  /// constructor, if the 'startOnInit' parameter was set to [true].
  ///
  /// Resumes the default ticker operation is it was previously paused and returns true else just
  /// returns false.
  bool play(){
    if(_isNotDisposed){
      if(_t.isActive) debugPrint("Please call the start method() before calling the play() method.");
      if(_t.muted) {
        _pD += DateTime.now().difference(_pT);
        _t.muted = false;
        return true;
      }
      return false;
    }
    return null;
  }

  /// This is a simple method that interfaces the [play] and tries to resume the playing of a ticker
  /// after the given [duration] of time. It returns the return value returned by the [play] method
  /// as a [Future]<[bool]>.
  Future<bool> playAfter(Duration d) => _isNotDisposed ? Future.delayed(d,play) : null;

  /// The [pause] method pauses the ticker operation that's currently active. This doesn't make the
  /// current ticker inactive but just pauses it (abstract). Calling this method on an un-disposed
  /// [TickerNotifier] makes the getter [isPlaying] return false and [isNotPlaying] return true.
  ///
  /// This method pauses the current ticker and returns [true], if it was previously paused and active,
  /// else returns [false].
  bool pause(){
    if(_isNotDisposed){
      if(_t.muted) return false;
      _pT = DateTime.now();
      return _t.muted = true;
    }
    return null;
  }

  /// This is a simple method that interfaces the [pause] and tries to pause the ticker that could
  /// have been ticking after the given [duration] of time. It returns the return value returned by
  /// the [pause] method as a [Future]<[bool]>
  Future<bool> pauseAfter(Duration d) => _isNotDisposed ? Future.delayed(d,pause) : null;

  /// Stops the current async operation that is being performed by the [TickerNotifier]. If you are
  /// trying to [stop] the polling being done by the async method [poll] or [pollFor] with the
  /// intention of being able to start it again via the [stop] method then it is recommended to use
  /// the method [pause]/[play] instead, as the [start] method would only work for the
  /// [TickerNotifier]'s default internal ticker.
  ///
  /// This method stops the ticker and returns true, if the ticker was previously active else just
  /// returns false.
  bool stop() {
    if(_isNotDisposed) {
      if(_t.isActive) {
        _t.stop();
        return true;
      }
      return false;
    }
    return null;
  }

  /// This is a simple method that interfaces the [stop] and tries to stop the ticker that could have
  /// been active after the given [duration] of time. It returns the return value returned by the
  /// [stop] method as a [Future]<[bool]>.
  Future<bool> stopAfter(Duration duration) => _isNotDisposed ? Future.delayed(duration,stop) : null;

  /// Disposes the current [TickerNotifier]. In order to re-use this instance, you'll need to call
  /// the method [init]. However, it is highly recommended that you complete all the operations that
  /// you perform and then dispose it in one go, unless you want to re-use the state in your code's
  /// logic.
  bool dispose() {
    if(super.dispose()){
      _t.stop(canceled: true);
      _t.dispose();
      _t = null;
    }
    return false;
  }

  /// The return value states whether a poll/tick operation is currently being performed [true] or
  /// not [false]. This getter shall throw an error if the [TickerNotifier] is already disposed.
  ///
  /// Returns [true] when the ticker is not paused or has not been stopped else false.
  bool get isPlaying => _isNotDisposed ? _t.isTicking : null;

  /// The return value states whether a poll/tick operation is currently being performed [false] or
  /// not [true]. This getter shall throw an error if the [TickerNotifier] is already disposed.
  ///
  /// Returns [true] when the ticker is paused or has been stopped or has not started yet, else false.
  bool get isNotPlaying => _isNotDisposed ? !_t.isTicking : null;

  /// The return value states whether a poll/tick operation is currently active [true] or
  /// not [false]. This getter shall throw an error if the [TickerNotifier] is already disposed.
  ///
  /// Returns [true] when the ticker has not been stopped or is in pause/play state, else [false] in
  /// stopped state.
  bool get isActive => _isNotDisposed ? _t.isActive : null;

  /// The return value states whether a poll/tick operation is currently being performed [true] or
  /// not [false]. This getter shall throw an error if the [TickNotifier] is already disposed.
  ///
  /// Returns [true] when the ticker has been stopped or has not started yet else [false].
  bool get isNotActive => _isNotDisposed ? !_t.isActive : null;

  /// This method polls a [TickerNotifier] with notifications over a fixed [duration] of time and
  /// returns the current instance of [Notifier] as a [Future]. A TickerProvider can be provided to
  /// this method via the [vsync] parameter.
  ///
  /// This polling can be:
  ///
  /// * Paused by the instance method [pause],
  /// * Continued by the instance method [play],
  /// * Completely stopped by the instance method [stop].
  /// * Restarted by calling this method again. (the [start] method is for the default ticker)
  ///
  /// By default, a [TickerNotifier] can only handle one polling or ticking at a time. Trying to
  /// call this method when a polling or ticking is already active would lead to a [StateError].
  /// To avoid this, once can pass [true] to the stopPrevious parameter. This will entirely stop
  /// the previous polling/ticking and start a new one altogether. (Don't do it manually!)
  Future<TickerNotifier> pollFor(Duration duration, {TickerProvider vsync, bool stopPrevious=false}) {
    if (_isNotDisposed) {
      if(stopPrevious??false) _t.dispose();
      if(_t.isActive) throw StateError("A TickerNotifier can control only one form of ticking or polling at a time. Please pass true to the stopPrevious parameter, while calling the method pollFor.");
      if (duration == Duration.zero) return Future.value(this);
      duration=duration.abs();
      _pD = Duration.zero;
      Function onTick = (d) {
        d-=_pD;
        if (d>duration) return _t..stop()..dispose();
        call();
      };
      _t = vsync == null ? Ticker(onTick) : vsync.createTicker(onTick);
      return _t.start().then((value){_t = Ticker(this);return this;});
    }
    return null;
  }

  /// This method polls the [TickerNotifier] with notifications for a fixed number of [times] and
  /// returns the duration taken to poll the Notifier as a future. A TickerProvider can be passed
  /// via the [vsync] parameter.
  ///
  /// This polling can be:
  ///
  /// * Paused by the instance method [pause],
  /// * Continued by the instance method [play],
  /// * Completely stopped by the instance method [stop].
  /// * Restarted by calling this method again. (the [start] method is for the default ticker)
  ///
  /// By default, a [TickerNotifier] can only handle one polling or ticking at a time. Trying to
  /// call this method when a polling or ticking is already active would lead to a [StateError].
  /// To avoid this, once can pass [true] to the stopPrevious parameter. This will entirely stop
  /// the previous polling/ticking and start a new one altogether. (Don't do it manually!)
  Future<Duration> poll(int times, {TickerProvider vsync, bool stopPrevious=false}) {
    if (_isNotDisposed) {
      Duration end;
      if(stopPrevious??false) _t.dispose();
      if(_t.isActive) throw StateError("A TickerNotifier can control only one form of ticking or polling at a time. Please pass true to the stopPrevious parameter, while calling the method poll.");
      if (times == 0) return Future.value(Duration.zero);
      times = times.abs();
      Function onTick = (d) {
        if (times--==0) {
          end = d;
          return _t..stop()..dispose();
        }
        call();
      };
      _t = vsync == null ? Ticker(onTick) : vsync.createTicker(onTick);
      return _t.start().then((value){_t = Ticker(this); return end;});
    }
    return null;
  }

  /// The [init] method can be used to re-init a disposed [TickerNotifier].
  ///
  /// If the [TickerNotifier] was previously disposed, it re-init s it with the specified values and
  /// returns true, else it just returns false.
  bool init({
    bool startOnInit = false,
    bool pauseOnInit = false,
    String debugLabel,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Function,dynamic) removeListenerOnError,
  })
  {
    if(super.init(
        attachNotifiers: attachNotifiers,
        listenToNotifiers: listenToNotifiers,
        mergeNotifiers: mergeNotifiers,
        initialListeners: initialListeners,
        removeListenerOnError: removeListenerOnError,
    )) {
      _t = Ticker(this, debugLabel: debugLabel);
      if(startOnInit??false) start(play: pauseOnInit!=true);
      _t.muted = pauseOnInit==true;
    }
    return false;
  }


  TickerNotifier({
    bool startOnInit = false,
    bool pauseOnInit = false,
    String debugLabel,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Function,dynamic) removeListenerOnError,
  }) : super(
    attachNotifiers: attachNotifiers,
    listenToNotifiers: listenToNotifiers,
    mergeNotifiers: mergeNotifiers,
    initialListeners: initialListeners,
    removeListenerOnError: removeListenerOnError,
  ) {
    _t = Ticker(this, debugLabel: debugLabel);
    if(startOnInit??false) start(play: pauseOnInit!=true);
    _t.muted = pauseOnInit==true;
  }
}

// Had tried using mixin but an error occurred since multiple signatures of the method call was
// found by the VM.
// So the idea was dropped. call([dynamic]) and call([T,`bool`])

class TickerValNotifier<T> extends ValNotifier<T>
{
  Ticker _t;
  Duration _pD = Duration.zero;
  DateTime _pT;

  /// The [start] method can be used to start the default ticker of the current [TickerValNotifier] if
  /// no other ticker operation like polling (or even the default operation) is going on.
  ///
  /// The parameter [play] in this context can be used to not play the ticker operation as soon as
  /// the ticker starts by passing false to it. Passing any other value (true/null) to this parameter
  /// will make it perform the default operation (play).
  ///
  /// It starts the default operation and returns true, if an operation was not previously active else
  /// just returns false.
  bool start({bool play=true}){
    if(_isNotDisposed){
      if(_t.isActive){
        if(isNotPlaying) debugPrint("$runtimeType#$hashCode: I have already been started! Please consider using the play() method.");
        return false;
      }
      _pD = Duration.zero;
      _t.start();
      _t.muted = play!=true;
      return true;
    }
    return null;
  }

  /// This is a simple method that interfaces the [start] and tries to start the ticker that could
  /// have been ticking after the given [duration] of time. It returns the return value returned by
  /// the [pause] method as a [Future]<[bool]>
  Future<bool> startAfter(Duration d) => _isNotDisposed ? Future.delayed(d,start) : null;

  /// The [play] method resumes the playing of an ticker operation that had been previously either
  /// stopped by the [pause] method or had been set to pause by default while starting it via
  /// the named parameter 'play' of the [start] method which could have implicitly done by the
  /// constructor, if the 'startOnInit' parameter was set to [true].
  ///
  /// Resumes the default ticker operation is it was previously paused and returns true else just
  /// returns false.
  bool play(){
    if(_isNotDisposed){
      if(_t.muted) {
        _pD += DateTime.now().difference(_pT);
        _t.muted = false;
        return true;
      }
      return false;
    }
    return null;
  }

  /// This is a simple method that interfaces the [play] and tries to resume the playing of a ticker
  /// after the given [duration] of time. It returns the return value returned by the [play] method
  /// as a [Future]<[bool]>.
  Future<bool> playAfter(Duration d) => _isNotDisposed ? Future.delayed(d,play) : null;

  /// The [pause] method pauses the ticker operation that's currently active. This doesn't make the
  /// current ticker inactive but just pauses it (abstract). Calling this method on an un-disposed
  /// [TickerValNotifier] makes the getter [isPlaying] return false and [isNotPlaying] return true.
  ///
  /// This method pauses the current ticker and returns [true], if it was previously paused and active,
  /// else returns [false].
  bool pause(){
    if(_isNotDisposed){
      if(_t.muted) return false;
      _pT = DateTime.now();
      return _t.muted = true;
    }
    return null;
  }

  /// This is a simple method that interfaces the [pause] and tries to pause the ticker that could
  /// have been ticking after the given [duration] of time. It returns the return value returned by
  /// the [pause] method as a [Future]<[bool]>
  Future<bool> pauseAfter(Duration d) => _isNotDisposed ? Future.delayed(d,pause) : null;

  /// Stops the current async operation that is being performed by the [TickerValNotifier]. If you are
  /// trying to [stop] the polling being done by the async method [poll] or [pollFor] with the
  /// intention of being able to start it again via the [stop] method then it is recommended to use
  /// the method [pause]/[play] instead, as the [start] method would only work for the
  /// [TickerValNotifier]'s default internal ticker.
  ///
  /// This method stops the ticker and returns true, if the ticker was previously active else just
  /// returns false.
  bool stop() {
    if(_isNotDisposed) {
      if(_t.isActive) {
        _t.stop();
        return true;
      }
      return false;
    }
    return null;
  }

  /// This is a simple method that interfaces the [stop] and tries to stop the ticker that could have
  /// been active after the given [duration] of time. It returns the return value returned by the
  /// [stop] method as a [Future]<[bool]>.
  Future<bool> stopAfter(Duration d) => _isNotDisposed ? Future.delayed(d,stop) : null;

  /// Disposes the current [TickerNotifier]. In order to re-use this instance, you'll need to call
  /// the method [init]. However, it is highly recommended that you complete all the operations that
  /// you perform and then dispose it in one go, unless you want to re-use the state in your code's
  /// logic.
  bool dispose() {
    if(super.dispose()){
      _t.stop(canceled: true);
      _t.dispose();
      _t = null;
    }
    return false;
  }

  /// The return value states whether a poll/tick operation is currently being performed [true] or
  /// not [false]. This getter shall throw an error if the [TickerValNotifier] is already disposed.
  ///
  /// Returns [true] when the ticker is not paused or has not been stopped else false.
  bool get isPlaying => _isNotDisposed ? _t.isTicking : null;

  /// The return value states whether a poll/tick operation is currently being performed [false] or
  /// not [true]. This getter shall throw an error if the [TickerValNotifier] is already disposed.
  ///
  /// Returns [true] when the ticker is paused or has been stopped or has not started yet, else false.
  bool get isNotPlaying => _isNotDisposed ? !_t.isTicking : null;

  /// The return value states whether a poll/tick operation is currently active [true] or
  /// not [false]. This getter shall throw an error if the [TickerValNotifier] is already disposed.
  ///
  /// Returns [true] when the ticker has not been stopped or is in pause/play state, else [false] in
  /// stopped state.
  bool get isActive => _isNotDisposed ? _t.isActive : null;

  /// The return value states whether a poll/tick operation is currently being performed [true] or
  /// not [false]. This getter shall throw an error if the [TickerValNotifier] is already disposed.
  ///
  /// Returns [true] when the ticker has been stopped or has not started yet else [false].
  bool get isNotActive => _isNotDisposed ? !_t.isActive : null;

  /// This method polls a [TickerValNotifier] with notifications over a fixed [duration] of time and
  /// returns the current instance of [Notifier] as a [Future]. A TickerProvider can be provided to
  /// this method via the [vsync] parameter.
  ///
  /// This polling can be:
  ///
  /// * Paused by the instance method [pause],
  /// * Continued by the instance method [play],
  /// * Completely stopped by the instance method [stop].
  /// * Restarted by calling this method again. (the [start] method is for the default ticker)
  ///
  /// By default, a [TickerValNotifier] can only handle one polling or ticking at a time. Trying to
  /// call this method when a polling or ticking is already active would lead to a [StateError].
  /// To avoid this, once can pass [true] to the stopPrevious parameter. This will entirely stop
  /// the previous polling/ticking and start a new one altogether. (Don't do it manually!)
  Future<TickerValNotifier<T>> pollFor(Duration duration, {TickerProvider vsync, bool stopPrevious=false}) {
    if (_isNotDisposed) {
      if(stopPrevious??false) _t.dispose();
      if(_t.isActive) throw StateError("TickerValNotifier<$T> can control only one form of ticking or polling at a time. Please pass true to the stopPrevious parameter, while calling the method pollFor.");
      if (duration == Duration.zero) return Future.value(this);
      duration=duration.abs();
      _pD = Duration.zero;
      Function onTick = (d) {
        d -= _pD;
        if (d>duration) return _t..stop()..dispose();
        call(_val,false);
      };
      _t = vsync == null ? Ticker(onTick) : vsync.createTicker(onTick);
      return _t.start().then((value){_t = Ticker((d)=>this(_val)); return this;});
    }
    return null;
  }

  /// This method polls the [TickerValNotifier] with notifications for a fixed number of [times] and
  /// returns the duration taken to poll the Notifier as a future. A TickerProvider can be passed
  /// via the [vsync] parameter.
  ///
  /// This polling can be:
  ///
  /// * Paused by the instance method [pause],
  /// * Continued by the instance method [play],
  /// * Completely stopped by the instance method [stop].
  /// * Restarted by calling this method again. (the [start] method is for the default ticker)
  ///
  /// By default, a [TickerValNotifier] can only handle one polling or ticking at a time. Trying to
  /// call this method when a polling or ticking is already active would lead to a [StateError].
  /// To avoid this, once can pass [true] to the stopPrevious parameter. This will entirely stop
  /// the previous polling/ticking and start a new one altogether. (Don't do it manually!)
  Future<Duration> poll(int times, {TickerProvider vsync, bool stopPrevious=false}) {
    if (_isNotDisposed) {
      Duration end;
      if(stopPrevious??false) _t.dispose();
      if(_t.isActive) throw StateError("TickerValNotifier<$T> can control only one form of ticking or polling at a time. Please pass true to the stopPrevious parameter, while calling the method poll.");
      if (times == 0) return Future.value(Duration.zero);
      times = times.abs();
      Function onTick = (d) {
        if (times--==0) {
          end = d;
          return _t..stop()..dispose();
        }
        call(_val,false);
      };
      _t = vsync == null ? Ticker(onTick) : vsync.createTicker(onTick);
      return _t.start().then((value){_t = Ticker((d)=>this()); return end;});
    }
    return null;
  }

  /// The [init] method can be used to re-init a disposed [TickerNotifier].
  ///
  /// If the [TickerNotifier] was previously disposed, it re-init s it with the specified values and
  /// returns true, else it just returns false.
  bool init({
    T initialVal,
    bool startOnInit = false,
    bool pauseOnInit = false,
    String debugLabel,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Function,dynamic) removeListenerOnError,
  })
  {
    if(super.init(
      initialVal: initialVal,
      attachNotifiers: attachNotifiers,
      listenToNotifiers: listenToNotifiers,
      mergeNotifiers: mergeNotifiers,
      initialListeners: initialListeners,
      removeListenerOnError: removeListenerOnError,
    )){
      _t = Ticker((d)=>call(), debugLabel: debugLabel);
      if(startOnInit??false) start(play: pauseOnInit!=true);
      _t.muted = pauseOnInit==true;
    }
    return false;
  }

  TickerValNotifier({
    T initialVal,
    bool startOnInit = false,
    bool pauseOnInit = false,
    String debugLabel,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Function,dynamic) removeListenerOnError,
  }) : super(
    initialVal: initialVal,
    attachNotifiers: attachNotifiers,
    listenToNotifiers: listenToNotifiers,
    mergeNotifiers: mergeNotifiers,
    initialListeners: initialListeners,
    removeListenerOnError: removeListenerOnError
  ) {
    _t = Ticker((_)=>this(), debugLabel: debugLabel);
    if(startOnInit) start(play: pauseOnInit!=true);
    else _t.muted = pauseOnInit==true;
  }
}

class TweenNotifier<T> extends ValNotifier<T>
{

  Ticker _t;
  Duration _pD = Duration.zero;
  DateTime _pT;

  TweenNotifier({
    T initialVal,
    String debugLabel,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Function,dynamic) removeListenerOnError,
  }) : super(
          initialVal: initialVal,
      attachNotifiers: attachNotifiers,
      listenToNotifiers: listenToNotifiers,
      mergeNotifiers: mergeNotifiers,
      initialListeners: initialListeners,
      removeListenerOnError: removeListenerOnError);

  bool play(){
    if(_isNotDisposed||_t==null){
      if(_t.muted) {
        _pD += DateTime.now().difference(_pT);
        _t.muted = false;
        return true;
      }
      return false;
    }
    return null;
  }

  bool pause(){
    if(_isNotDisposed||_t==null){
      if(_t.muted) return false;
      _pT = DateTime.now();
      return _t.muted = true;
    }
    return null;
  }

  bool dispose() {
    if(super.dispose()){
      if(_t!=null){
        _t.stop(canceled: true);
        _t.dispose();
        _t = null;
      }
    }
    return false;
  }

  bool get isPerformingTween => _isNotDisposed?(_t!=null && _t.isTicking):null;
  bool get isNotPerformingTween => _isNotDisposed?(_t==null || !_t.isTicking):null;

  bool get hasPerformedATween => _isNotDisposed?_t!=null:null;
  bool get hasNotPerformedATween => _isNotDisposed?_t==null:null;

  bool get isPaused => _isNotDisposed&&_t!=null&&_t.isActive?_t.muted:null;
  bool get isPlaying => _isNotDisposed&&_t!=null&&_t.isActive?!_t.muted:null;

  Future<TweenNotifier<T>> performTween(Tween<T> tween, Duration duration, {int loop=1, bool reverse=false, Curve curve = Curves.linear}) async {
    if(_isNotDisposed){
      if(_t?.isActive ?? false) throw StateError("A TweenNotifier cannot perform more than one controllable animation. Please wait for the current animation to get over.");
      return super.performTween(tween, duration, loop: loop, reverse: reverse, curve: curve).then((value) => this);
    }
    return null;
  }

  Future<TweenNotifier<T>> performTweens(Iterable<Tween<T>> tweens, Duration duration, {int loop=1,bool reverse=false, Curve curve = Curves.linear}) async {
    if(_isNotDisposed){
      if(_t?.isActive ?? false) throw StateError("A TweenNotifier cannot perform more than one controllable animation. Please wait for the current animation to get over.");
      return super.performTweens(tweens, duration, loop: loop, reverse: reverse, curve: curve).then((value) => this);
    }
    return null;
  }

  Future<TweenNotifier<T>> performCircularTween(Tween<T> tween, Duration duration, {int circles=1, bool reverse=false, Curve firstCurve = Curves.linear, Curve secondCurve = Curves.linear}) async {
    if(_isNotDisposed){
      if(_t?.isActive ?? false) throw StateError("A TweenNotifier cannot perform more than one controllable animation at once. Please wait for the current animation to get over.");
      return super.performCircularTween(tween, duration, circles: circles, reverse: reverse, firstCurve: firstCurve, secondCurve: secondCurve).then((value) => this);
    }
    return null;
  }

  Future<TweenNotifier<T>> interpolate(Tween<T> tween, Iterable<T> values, Duration totalDuration, {int loop=1, bool reverse=false, Curve curve = Curves.linear, Iterable<Curve> curves}) async {
    if(_isNotDisposed){
      if(_t?.isActive ?? false) throw StateError("A TweenNotifier cannot perform more than one controllable animation at once. Please wait for the current animation to get over.");
      return super.interpolate(tween, values, totalDuration, loop: loop, reverse: reverse, curve: curve, curves: curves).then((value) => this);
    }
    return null;
  }

  Future<TweenNotifier<T>> circularInterpolation(Tween<T> tween, Iterable<T> values, Duration totalDuration, {int circles=1, Curve firstCurve=Curves.linear, Curve secondCurve=Curves.linear, Iterable<Curve> firstCurves, Iterable<Curve> secondCurves})
  {
    if(_isNotDisposed){
      if(_t?.isActive ?? false) throw StateError("A TweenNotifier cannot perform more than one controllable animation at once. Please wait for the current animation to get over.");
      return super.circularInterpolation(Tween<T>(), values, totalDuration, circles: circles, firstCurve: firstCurve, secondCurve: secondCurve, firstCurves: firstCurves, secondCurves: secondCurves).then((value) => this);
    }
    return null;
  }

  Future<TweenNotifier<T>> _interpolate(Tween<T> tween, Iterable<T> values, Duration duration, {int loop=1, bool reverse=false, Iterable<Curve> curves, Ticker t}) async {

    Curve curve;

    if(reverse??=false) {
      values = values.toList().reversed;
      curves = curves.toList().reversed;
    }

    int i;

    t = Ticker((d) async {
      d-=_pD;
      if (d > duration) {
        call(tween.end);
        return t..stop();
      }
      return call(tween.transform(curve.transform(d.inMilliseconds / duration.inMilliseconds)));
    });

    tween.end = values.first;

    _t = t;

    return Future.doWhile(() async {
      i = 1;
      do {
        tween.begin = tween.end;
        tween.end = values[i];
        curve = curves[i-1];
        _pD = Duration.zero;
        await _t.start();
      } while(++i!=values.length);
      return --loop!=0;
    }).then((_){
      _t.dispose();
      return this;
    });
  }

  Future<Ticker> _performTween(Tween<T> tween, Duration duration, {int loop=1, bool reverse=false, Curve curve = Curves.linear, Ticker t}) async {

    T _;
    reverse??=false;

    if(t==null){
      if(reverse) {
        _ = tween.begin;
        tween.end = tween.begin;
        tween.begin = _;
        reverse = null;
      }
      t = Ticker((d) {
        d-=_pD;
        if (d > duration) {
          call(tween.end);
          return _t..stop();
        }
        return call(tween.transform(curve.transform(d.inMilliseconds / duration.inMilliseconds)));
      });
    }

    loop = _times(loop);
    _t = t;
    while(loop--!=0) {
      _pD = Duration.zero;
      await _t.start();
    }

    if(reverse==null){
      tween.begin = tween.end;
      tween.end = _;
    }
    return _t;
  }

  Future<Duration> poll(int times, {TickerProvider vsync}){
    if(_isNotDisposed){
      if(_t?.isActive ?? false) throw StateError("A TweenNotifier cannot get polled while it's being animated. Please wait for the previous animation to get over using await/then.");
      return super.poll(times, vsync: vsync);
    }
    return null;
  }

  Future<TweenNotifier> pollFor(Duration duration, {TickerProvider vsync}){
    if(_isNotDisposed){
      if(_t?.isActive ?? false) throw StateError("A TweenNotifier cannot get polled while it's being animated. Please wait for the previous animation to get over using await/then.");
      return super.pollFor(duration, vsync: vsync);
    }
    return null;
  }
}

extension Iterable_ValNotifier<T> on Iterable<ValNotifier<T>> {
  Iterable<ValNotifier<T>> nullNotify() => map((n)=>n?.nullNotify()).toList();
  ValNotifier<T> merge([Iterable<ValNotifier<T>> notifiers]) => ValNotifier<T>._().._addListeners(_listeners).._addListeners(notifiers._listeners);
}

/// [TimedNotifier] is just a simple Notifier class that interfaces a [Timer] to make polling 'at a
/// specific interval' instead of just polling it over a (un)fixed duration of time.
///
/// * The [start] method can be used to start the polling, either at a specific interval or as soon
/// as it can (default).
///
/// * The [stop] method can be used to stop the [Timer] that was started either by the [start] or the
/// [notifyAtInterval] method.
///
/// * The [pause] method can be used to pause the internal [Timer] of the [TimedNotifier]
///
/// * The [play] method can be used to resume the internal [Timer] of the [TimedNotifier]
///
/// * The [interval] getter and setter can be used to either get the current interval or dynamically
/// change it to another Duration, even when it's active or is ticking.
///
/// Note: The [TimedNotifier] can also directly be started while instantiating it by giving its
/// interval parameter a non-null [Duration] and also optionally paused.
///
/// Also, this is not the right class if you are looking for a [Notifier] to create a timer that
/// actually display the current time or perhaps a stopwatch.
class TimedNotifier extends Notifier
{

  Timer _t;
  Duration _interval;
  DateTime _lastTick;
  Duration _pending;

  DateTime get _nextTick => _lastTick.add(_interval);

  Duration get timeForNextTick => _pending??_nextTick.difference(DateTime.now());
  Duration get timeSinceLastTick => DateTime.now().difference(_lastTick);
  DateTime get lastTick => _isNotDisposed ? _lastTick : null;
  Duration get interval => _isNotDisposed ? _interval : null;

  set interval(Duration interval) {
    assert(interval!=null,"Could not set the timer to a null duration.");
    if(interval==_interval) return;
    _t?.cancel();
    if(isPlaying) call();
    _interval = interval.abs();
    _genTimer();
  }

  /// A getter whose return value determines whether the [Timer] that is internally maintained
  /// [isActive] or not. If it returns true, that means its active else is inactive.
  bool get isActive => _isNotDisposed ? _t?.isActive==true : null;

  /// A getter whose return value determines whether the [Timer] that is internally maintained
  /// [isInActive] or not. If it returns true, that means its inactive else its active.
  bool get isInActive => _isNotDisposed ? _t?.isActive!=true : null;

  /// The [start] method starts the internal timer of the [TickerNotifier] to notify the listeners
  /// at a specific [interval] (default: [Duration.zero]). The [play] parameter specifies whether
  /// or not the internal [Timer] start in play state as soon as it starts or in paused state.
  ///
  /// If the [play] parameter, receives false the [TickerNotifier] will start the internal [Timer]
  /// in the paused state else for true/null(/default) it shall start in play state.
  ///
  /// This method starts the internal timer with the specified [duration] and returns true if it was
  /// previously inactive else it will return false.
  ///
  /// In order to force start the internal [Timer] one can use the [reset] method, that stops the
  /// previous timer (if any) and starts a new one with a new duration internally.
  bool start([Duration interval=Duration.zero, bool play=true])
  {
    if(_isNotDisposed) {
      if(_t?.isActive ?? false) return false;
      _interval = interval;
      _pending = play!=true ? Duration.zero : null;
      _genTimer();
      return true;
    }
    return null;
  }

  void _genTimer() => _t = Timer.periodic(_interval, (d){
    _lastTick = DateTime.now();
    if(isPlaying) call();
  });

  /// The return value of this getter determines whether the [Timer] that is internally maintained by
  /// this [TickerNotifier] is notifying it's listeners on each interval or not.
  ///
  /// If it returns true, that means it is notifying it's listeners else false.
  bool get isPlaying => _isNotDisposed ? _pending==null : null;

  /// The return value of this getter determines whether the [Timer] that is internally maintained by
  /// this [TickerNotifier] is notifying it's listeners on each interval or not.
  ///
  /// If it returns true, that means it is not notifying it's listeners else it is (false).
  bool get isPaused  => _isNotDisposed ? _pending!=null : null;

  /// The [play] method can be used to resume notifications of the timer that is being internally
  /// maintained.
  bool play() {
    if(_isNotDisposed){
      if(isPlaying) return false;
      _t.cancel();

      Future.delayed(_pending,(){
        _pending=null;
        _genTimer();
      });
      return true;
    }
    return null;
  }

  bool pause() {
    if(_isNotDisposed){
      if(isPlaying){
        _pending = timeForNextTick;
        return true;
      }
      return false;
    }
    return null;
  }

  bool stop()
  {
    if(_isNotDisposed) {
      if(_t.isActive) {
        _t.cancel();
        return true;
      }
      return false;
    }
    return null;
  }

  Timer notifyAtInterval(Duration interval){
    if(_isNotDisposed){
      stop();
      _genTimer();
      return _t;
    }
    return null;
  }

  void reset([Duration duration=Duration.zero, bool play=true]){
    if(_isNotDisposed){
      stop();
      _interval = interval;
      _pending = play!=true?Duration.zero:null;
      _genTimer();
    }
  }

  bool init({
    Duration interval,
    bool pauseOnInit = false,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Function,dynamic) removeListenerOnError,
  }){
    if(super.init(
      attachNotifiers: attachNotifiers,
      listenToNotifiers: listenToNotifiers,
      mergeNotifiers: mergeNotifiers,
      initialListeners: initialListeners,
      removeListenerOnError: removeListenerOnError,
    )) {
      if(interval!=null) start(interval.abs(), pauseOnInit!=true);
      else _pending = pauseOnInit==true?Duration.zero:null;
      return true;
    }
    return false;
  }

  bool dispose() {
    if(super.dispose()){
      _t.cancel();
      _t = null;
      _pending = null;
      _interval = null;
      return true;
    }
    return false;
  }

  TimedNotifier({
    Duration interval,
    bool pauseOnInit = false,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Function,dynamic) removeListenerOnError
  }) : super(
      attachNotifiers: attachNotifiers,
      listenToNotifiers: listenToNotifiers,
      mergeNotifiers: mergeNotifiers,
      initialListeners: initialListeners) {
    if(interval!=null) start(interval.abs(), pauseOnInit!=true);
    else _pending = pauseOnInit==true?Duration.zero:null;
  }
}

extension DateTime_Ease on DateTime
{
  DateTime operator +(Duration duration) => add(duration??Duration.zero);
  Duration operator -(DateTime dateTime)=>difference(dateTime);
}

/// The [SWNotifier] class is a maintains an internal abstract stopwatch that can be [start]ed,
/// [stop]ped, [pause]d and then [play]ed as per your requirements. You can even dynamically change
/// the [elapsed] duration by overwriting it, or adding/deducting/multiply/dividing it by a certain
/// [Duration] or [num]. This class was made with the intention of making creating a stopwatch
/// easier, however it can also be indirectly used as a live timer with negative duration and by
/// considering the absolute duration with the help of [Duration.abs]. (A simple listener can be
/// attached to see when the [Timer] should be cancelled)
class SWNotifier extends TickerValNotifier<Duration>
{
  DateTime _start;

  /// Returns the duration elapsed by the internal abstract stopwatch.
  ///
  /// If the internal ticker is not active, it will return [Duration.zero] else the elapsed time.
  Duration get elapsed => _isNotDisposed ? (isActive ? _elapsed : Duration.zero) : null;
  Duration get _elapsed => (isPlaying?DateTime.now():_pT).difference(_start) - _pD;

  /// Sets a new elapsed duration for the internal abstract stopwatch. If the internal ticker or
  /// abstract stopwatch isn't active it throws an [StateError]. Also, the [elapsed] duration passed
  /// to this setter method is expected to not be null.
  set elapsed(Duration elapsed) {
    assert(elapsed!=null,"SWNotifier#$hashCode: The elapsed duration of cannot be set to null!");
    if(isNotActive) throw StateError("SWNotifier#$hashCode: Couldn't modify the elapsed duration since I have not been started yet. Please use the start() method on me before trying to modify/play with this value.");
    _start=DateTime.now()+(-elapsed);
  }

  /// Starts the internal ticker (and hence the abstract stopwatch) of the current [SWNotifier].
  /// If the stopwatch has already been start it returns false else starts the stopwatch and returns
  /// true.
  ///
  /// One can optionally decide to pause the stopwatch while starting it by passing false to the
  /// named parameter [play].
  bool start({bool play=true}) {
    if(_isNotDisposed) {
      if(super.start(play: play)) {
        if(play!=true) _pT = _start = DateTime.now();
        else _start = DateTime.now();
        return true;
      }
      return false;
    }
    return null;
  }

  /// Stops the internal ticker (and hence the abstract stopwatch) of the current [SWNotifier].
  /// If the stopwatch has already been stopped it returns false else it stops the stopwatch and
  /// returns true. If you want to reset the stopwatch while stopping it, then please pass true to
  /// the named parameter [reset] when the abstract stopwatch is active. Trying to reset it when the
  /// stopwatch is inactive wouldn't reset the [elapsed] duration of the abstract stopwatch. You
  /// could use the [reset] method then and pass values to it's parameters as per your requirements.
  bool stop({bool reset=false})
  {
    if(_isNotDisposed) {
      if(super.stop()){
        _start = null;
        if(reset==true) call(Duration.zero, false);
        return true;
      }
      return false;
    }
    return null;
  }

  /// The method [reset] force resets the internal abstract stopwatch that is maintained by this
  /// [SWNotifier]. By default, this method starts playing the stopwatch as soon as it is reset.
  /// To change this behavior, please pass false to the named parameter [play] of this method.
  void reset({bool play=true}) {
    if(_isNotDisposed){
      stop(reset: true);
      start(play: play);
    }
  }

  /// This method jumps the abstract stopwatch to the given [duration]. If the [SWNotifier] is
  /// not active it returns false else it jumps to the given [duration] and then returns true.
  ///
  /// This method is just an abstraction to the setter method [elapsed]= that returns false instead
  /// of throwing an error unless its an assertion.
  bool jumpTo(Duration duration){
    if(_isNotDisposed) {
      assert(duration!=null,"SWNotifier:$hashCode Could not jump to duration null.");
      if(isActive){
        elapsed = duration;
        return false;
      }
      return false;
    }
    return null;
  }

  /// This method adds the given [duration] to the [elapsed] duration if the [SWNotifier] is active
  /// and returns true, else it just returns false.
  ///
  /// This method is just an abstraction to the setter method [elapsed]+= that returns false instead
  /// of throwing an error (if the [SWNotifier] is inactive) unless its an assertion.
  bool addElapsed(Duration duration){
    if(_isNotDisposed){
      assert(duration!=null,"SWNotifier:$hashCode Could not add null duration to elapsed.");
      if(isActive){
        elapsed+=duration;
        return false;
      }
      return false;
    }
    return null;
  }

  /// This method deducts the given [duration] to the [elapsed] duration if the [SWNotifier] is
  /// active and returns true, else it just returns false.
  ///
  /// This method is just an abstraction to the setter method [elapsed]-= that returns false instead
  /// of throwing an error (if the [SWNotifier] is inactive) unless its an assertion.
  bool deductElapsed(Duration duration) {
    if(_isNotDisposed){
      assert(duration!=null,"SWNotifier:$hashCode Could not deduct null duration to elapsed.");
      if(isActive){
        elapsed-=duration;
        return false;
      }
      return false;
    }
    return null;
  }

  /// This method multiplies the [elapsed] duration by the given number of [times]. If the
  /// [SWNotifier] is active it will return true else false.
  ///
  /// This method is just an abstraction to the setter method [elapsed]+= that returns false instead
  /// of throwing an error (if the [SWNotifier] is inactive) unless its an assertion.
  bool multiplyElapsed(num times){
    if(_isNotDisposed){
      assert(times!=null,"SWNotifier:$hashCode Could not multiply null to elapsed duration.");
      if(isActive){
        elapsed*=times;
        return false;
      }
      return false;
    }
    return null;
  }

  /// This method divides the [elapsed] duration by the given number of [times]. If the [SWNotifier]
  /// is active it will return true else false.
  ///
  /// This method is just an abstraction to the setter method [elapsed]+= that returns false instead
  /// of throwing an error (if the [SWNotifier] is inactive) unless its an assertion.
  bool divideElapsed(num times){
    if(_isNotDisposed) {
      assert(times!=null,"SWNotifier:$hashCode Could not divide null to elapsed duration.");
      if(isActive){
        elapsed~/=times;
        return false;
      }
      return false;
    }
    return null;
  }

  /// Returns the duration elapsed by the [SWNotifier]. Was created with the intention of hinting
  /// the user that elapsed can be used to perform laps (auto-complete).
  Duration lap() => elapsed;

  /// Returns the duration elapsed by the [SWNotifier]. Was created with the intention of hinting
  /// the user that elapsed can be used to perform splits (auto-complete).
  Duration split() => elapsed;

  /// The call method has been modified in a special way for the [SWNotifier].
  ///
  /// If you pass some non-null [elapsed] duration while calling a [SWNotifier] it simply jumps
  /// to that duration and starts playing from there. If you just want to notify a Duration for
  /// a moment while the [SWNotifier] is playing then please pass false to the second parameter
  /// [save]. This wouldn't jump to that the passed duration but would just notify it for a moment.
  /// However, it must be noted that it saves it, even if the save parameter is set to false.
  SWNotifier call([Duration elapsed,bool save=true]){
    if(_isNotDisposed) {
      if(_t.isActive&&save==true){
          if(elapsed!=null) _start=DateTime.now()+(-elapsed);
          return super.call(_elapsed);
        }
        return super.call(elapsed);
    }
    return null;
  }

  /// Can be used to re-init the [SWNotifier] once it's disposed. If its already disposed then
  /// it re-init s it and returns true else just returns false.
  /// 
  /// Note: The [initialVal] parameter just means initial value. It doesn't directly jump to that
  /// value, once the internal abstract stopwatch starts.
  bool init({
    Duration initialVal,
    bool startOnInit = false,
    bool pauseOnInit = false,
    String debugLabel,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Function,dynamic) removeListenerOnError,
  })
  {
    if(super.init(
      initialVal: initialVal ?? Duration.zero,
      debugLabel: debugLabel,
      attachNotifiers: attachNotifiers,
      listenToNotifiers: listenToNotifiers,
      mergeNotifiers: mergeNotifiers,
      initialListeners: initialListeners,
      removeListenerOnError: removeListenerOnError,
    )){
      if(startOnInit==true) start(play: pauseOnInit!=true);
      else _t.muted = pauseOnInit==true;
    }
    return false;
  }

  /// Disposes the current [SWNotifier]. Returns false if it was already disposed else disposes the
  /// [SWNotifier] and returns true.
  bool dispose() {
    if(super.dispose()){
      _start = null;
      return true;
    }
    return false;
  }
  
  SWNotifier({
    Duration initialVal,
    bool startOnInit = false,
    bool pauseOnInit = false,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Function,dynamic) removeListenerOnError,
  }) : super(
      initialVal: initialVal ?? Duration.zero,
      attachNotifiers: attachNotifiers,
      listenToNotifiers: listenToNotifiers,
      mergeNotifiers: mergeNotifiers,
      initialListeners: initialListeners) {
    if(startOnInit==true) start(play: pauseOnInit!=true);
    else _t.muted = pauseOnInit==true;
  }
}

/// An extension method that provides certain method to make certain operations easier in/while using
/// this plugin.
extension Iterable_<T> on Iterable<T> {
  /// A syntactic sugar for the [elementAt] function.
  T operator [](int index) => elementAt(index);

  /// The function [doWhileTrue] can be used to efficiently iterate an Iterable till the given condition is satisfied.
  ///
  /// If the function is able to iterate the list successfully the function will return [true] else [false].
  bool doWhileTrue(bool Function(T) computation) {
    for (T val in this) if (!computation(val)) return false;
    return true;
  }

  /// The function [doWhileFalse] can be used to efficiently iterate a list until a given condition remains unsatisfied.
  ///
  /// If the function is able to iterate the list successfully the function will return [false] else [true].
  bool doWhileFalse(bool Function(T) computation) {
    for (T val in this) if (computation(val)) return true;
    return false;
  }

  /// Checks whether the given element is present in the current [Iterable] by comparing it from the opposite
  /// class's operator== method.
  bool containsRevComp(Object element){
    for (T val in this) if (element==val) return true;
    return false;
  }

  /// Checks whether the given element is present in the current [Iterable] by comparing it with both classes'
  /// operator== method. For any given element present in the array, it returns true if either of the method(s)
  /// return true for any element else false is bluntly returned at the end.
  bool containsEitherComp(Object element){
    for (T val in this) if (element==val||val==element) return true;
    return false;
  }

  /// Checks whether the given element is present in the current [Iterable] by comparing it with both classes'
  /// operator== method. For any given element present in the array, it returns true if both the method(s)
  /// return true, else false is bluntly returned at the end.
  bool containsBothComp(Object element){
    for (T val in this) if (element==val&&val==element) return true;
    return false;
  }
}