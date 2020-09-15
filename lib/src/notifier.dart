part of notifier_plugin;

class Notifier extends Iterable<Notifier> {

  List<Function> _listeners = <Function>[]; // Auto-init
  bool Function(Error) _handleError;

  Notifier({
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool lockListenersOnInit = false,
    bool Function(Error) removeListenerOnError,
  }) {
    if (mergeNotifiers != null) _addListeners(mergeNotifiers._listeners);
    if (attachNotifiers != null) _attach(attachNotifiers);
    if (listenToNotifiers != null) _startListeningTo(listenToNotifiers);
    if (initialListeners != null) _addListeners(initialListeners);
    this.._handleError = removeListenerOnError;
    if(lockListenersOnInit==true) _listeners = List.from(_listeners, growable: false);
  }

  Notifier._();

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
      WidgetsFlutterBinding.ensureInitialized();
      return t.start().then((v) => this);
    }
    return null;
  }

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
      WidgetsFlutterBinding.ensureInitialized();
      return t.start().then((value) => end);
    }
    return null;
  }

  /// A method that can be used to async load a resource and then notify the listeners of the Notifier
  /// when the Future has been successfully completed. Can be used for a complete future.
  Future<Notifier> load(Future res) async => await res.then(this);

  /// Attach a ChangeNotifier to this [Notifier]
  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  bool attachChangeNotifier(ChangeNotifier changeNotifier) => _isNotDisposed?addListener(changeNotifier.notifyListeners)!=null:null;

  /// Detach a ChangeNotifier to this [Notifier]
  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  bool detachChangeNotifier(ChangeNotifier changeNotifier) => _isNotDisposed?removeListener(changeNotifier.notifyListeners):null;

  /// Check if the [Notifier] has attached this [ChangeNotifier]
  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  bool hasAttachedChangeNotifier(ChangeNotifier changeNotifier) => _isNotDisposed?hasListener(changeNotifier.notifyListeners):null;

  /// Make this [Notifier] listen to a [ChangeNotifier]
  bool startListeningToChangeNotifier(ChangeNotifier changeNotifier){
    if(_isNotDisposed){
      try {
        changeNotifier.addListener(this);
        return true;
      } catch(e) { return false; }
    }
    return null;
  }

  /// Tries to stop listening to the [changeNotifier] it was previously listening to.
  bool stopListeningToChangeNotifier(ChangeNotifier changeNotifier) {
    if(_isNotDisposed){
      try {
        changeNotifier.removeListener(this);
        return true;
      } catch(e) { return false; }
    }
    return null;
  }

  /// Attach a Stream to this [Notifier].
  bool attachStream(StreamController s) => _isNotDisposed?addListener(s.add)!=null:null;

  /// Detach a Stream that was previously attached to this [Notifier].
  bool detachStream(StreamController s) => _isNotDisposed?removeListener(s.add):null;

  /// Checks if the Notifier has attached the Stream
  bool hasAttachedStream(StreamController s) => _isNotDisposed?contains(s.add):null;

  /// Makes the [ValNotifier] listen to an existing [stream].
  StreamSubscription listenTo(Stream stream) => stream.listen(this);

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
    assert(!notifiers.contains(this),
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

  /// Attaches the [attachment]/passed Notifier to the current [Notifier].
//  static bool attachNotifierTo(Notifier notifier, Notifier attachment) =>notifier.attach(attachment);
//  /// A static implementation for [attach].
//  static Iterable<bool> attachNotifiersTo(Notifier notifier, Iterable<Notifier> attachments) => notifier?.attach(attachments);
//  /// A static implementation of [attach] that attaches a set of [Notifier] [attachments] to the given set of [notifiers].
//  static Iterable<bool> listAttachNotifierTo(
//          Iterable<Notifier> notifiers, Notifier attachment) =>
//      notifiers.map((notifier) => Notifier.attachNotifierTo(notifier, attachment));
//  /// A static implementation of [attach] that attaches a set of [Notifier] [attachments] to the given set of [notifiers].
//  static Iterable<bool> listAttachNotifiersTo(
//          Iterable<Notifier> notifiers, Iterable<Notifier> attachments) =>
//      notifiers
//          ?.map((notifier) => notifier.attach(attachments).elementAt(0))
//          ?.toList();
  bool hasAttached(Notifier notifier) =>
      _isNotDisposed ? _hasAttached(notifier) : null;

  bool _hasAttached(Notifier notifier) => _listeners.containsEitherComp(notifier);

  Iterable<bool> hasAttachedThese(Iterable<Notifier> notifiers) =>
      _isNotDisposed ? _hasAttachedThese(notifiers) : null;

  Iterable<bool> _hasAttachedThese(Iterable<Notifier> notifiers) =>
      notifiers?.map(_hasAttached)?.toList();

  bool hasAttachedAll(Iterable<Notifier> notifiers) =>
      _isNotDisposed ? _hasAttachedAll(notifiers) : null;

  bool _hasAttachedAll(Iterable<Notifier> notifiers) {
    for (Notifier notifier in notifiers)
      if (!_hasAttached(notifier)) return false;
    return true;
  }

//  Iterable<bool> isNotAttachedTo(Iterable<Notifier> notifier)=>hasAttached(notifier).notAll();
  bool detach(Notifier notifier) => _isNotDisposed ? _detach(notifier) : null;

  bool _detach(Notifier notifier) =>
      (notifier == null) ? null : removeListener(notifier);

  Iterable<bool> detachAll(Iterable<Notifier> notifiers) =>
      _isNotDisposed ? _detachAll(notifiers) : null;

  Iterable<bool> _detachAll(Iterable<Notifier> notifiers) =>
      removeListeners(notifiers?._notify);

  static bool detachNotifierOf(Notifier notifier, Notifier attachment) =>
      notifier?.removeListener(attachment);

//  static Iterable<bool> detachNotifiersOf(Notifier notifier, Iterable<Notifier> attachments) => notifier?.detach(attachments);
//  static Iterable<Iterable<bool>> listDetachNotifierOf(
//      Iterable<Notifier> notifiers, Notifier attachment)
//  => notifiers?.map((notifier) => notifier.detach(attachment));
//  static Iterable<Iterable<bool>> listDetachNotifiersOf(
//          Iterable<Notifier> notifiers, Iterable<Notifier> attachments) =>
// //      notifiers?.map((notifier) => notifier.detach(attachments));
  bool startListeningTo(Notifier notifier) {
    assert(notifier != null,
        "Notifier#$hashCode: A notifier cannot start listening to null.");
    assert(this != notifier,
        "Notifier#$hashCode: A notifier cannot start listening to itself.");
    return _startListeningTo(notifier);
  }

  bool _startListeningTo(Notifier notifier) => notifier?.attach(this);

  Iterable<bool> startListeningToAll(Iterable<Notifier> notifiers) =>
      _isNotDisposed ? _startListeningToAll(notifiers) : null;

  Iterable<bool> _startListeningToAll(Iterable<Notifier> notifiers) =>
      notifiers?.attach(notifiers);

  bool stopListeningTo(Notifier notifier) =>
      _isNotDisposed ? _stopListeningTo(notifier) : null;

  bool _stopListeningTo(Notifier notifier) => notifier?._detach(this);

  bool isListeningTo(Notifier notifiers) =>
      _isNotDisposed ? _isListeningTo(notifiers) : null;

  bool _isListeningTo(Notifier notifier) =>
      notifier?._hasAttached(this);

  Iterable<bool> isListeningToAll(Iterable<Notifier> notifiers) =>
      notifiers?.hasAttached(this);

  bool init({
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Error) removeListenerOnError,
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

  /// Adds a listener to the [Notifier] and returns the listener's [hashCode] if successfully added else returns [null].
  ///
  /// A static implementation of [addListener].
  static int addListenerToNotifier(Notifier notifier, Function listener) =>
      notifier?.addListener(listener);

  /// Adds a listener to all of the given [notifiers] and returns
  static Iterable<int> addListenerToNotifiers(Iterable<Notifier> notifiers, Function listener) =>
      notifiers.addListener(listener);

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

  bool _hasListener(Function listener) => _listeners.contains(listener);

  /// Checks if the passed [Notifier] has the passed [listener]. If it has it, it returns [true], else [false].
  static bool hasThisListener(Notifier notifier, Function listener) =>
      notifier?.hasListener(listener);

  /// Checks if the current [Notifier] has any listeners. If it has any, the function returns [true] else false.
  bool get hasListeners => _isNotDisposed && _hasListeners;

  bool get _hasListeners => _listeners.isNotEmpty;

  /// Checks if the passed [Notifier] has any listeners. If it has any, the function returns [true] else false.
  static bool hasAListener(Notifier notifier) => notifier?.hasListeners;

  /// Checks if the current [Notifier] has any of the given [listeners]. Returns [true] if it finds it else [false].
  bool hasAnyListener(Iterable<Function> listeners) =>
      _isNotDisposed ? _hasAnyListener(listeners) : null;

  bool _hasAnyListener(Iterable<Function> listeners) {
    for (Function listener in listeners)
      if (_listeners.contains(listener)) return true;
    return false;
  }

  /// Checks if the current [Notifier] has all of the given [listeners]. Returns [true] if it finds all else [false].
  bool hasAllListeners(Iterable<Function> listeners) =>
      _isNotDisposed ? _hasAllListeners(listeners) : null;

  bool _hasAllListeners(Iterable<Function> listeners) {
    for (Function listener in listeners)
      if (!_listeners.contains(listener)) return false;
    return true;
  }

  static bool hasTheseListeners(
          Notifier notifier, Iterable<Function> listeners) =>
      notifier?.hasAllListeners(listeners);

  static Iterable<bool> sHaveTheseListeners(
          Iterable<Notifier> notifiers, Iterable<Function> listeners) =>
      notifiers?.map((notifier) => notifier.hasAllListeners(listeners));

  void _call(Function listener) =>
      listener is Function() ? listener() : listener(null);

  Notifier call([dynamic _]) {
    if (_isNotDisposed) {
      for (int i = 0; i < _listeners.length; i++) {
        try {
          _call(_listeners[i]);
        } catch (e) {
          if (_handleError == null) rethrow;
          bool _ = _handleError(e);
          if (_)
            _listeners.removeAt(i--);
          else if (_ == null) rethrow;
        }
      }
      return this;
    }
    return null;
  }

  Notifier operator ~() => notify();

  Notifier get notify => this;

  Function get _notify => this;

  Notifier get notifyListeners => this;

  Notifier get sendNotification => this;

  /// A static function that notifies the [notifier] passed to it.
  static Notifier notifyNotifier(Notifier notifier) => ~notifier;

  /// A static function that notifies all the [notifiers] passed to it.
  static Iterable<Notifier> notifyAll(Iterable<Notifier> notifiers) =>
      notifiers?.map<Notifier>(notifyNotifier)?.toList();

  /// Tries to remove the passed [listener] if it is a listener of the current [Notifier].
  ///
  /// If the listener is a listener of the current [Notifier] and [isNotDisposed] then it returns [true] else false.
  bool removeListener(Function listener) =>
      _isNotDisposed ? _listeners.remove(listener) : null;

  bool _removeListener(Function listener) => _listeners.remove(listener);

  /// This function can be used to remove a specific listener by it's [hashCode], which can either be obtained as the
  /// return value of [addListener] or by manually storing the function as a variable and then obtaining it with the
  /// help of the getter hashCode. The return value determines if the transaction was successful or not.
  bool removeListenerByHashCode(int hashCode) =>
      _isNotDisposed ? _removeListenerByHashCode(hashCode) : null;

  bool _removeListenerByHashCode(int hashCode) {
    try {
      return _listeners.remove(
          _listeners.firstWhere((listener) => listener.hashCode == hashCode));
    } catch (e) {
      return false;
    }
  }

  /// An implementation of [removeListenerByHashCode] which deals with multiple [hashCodes]. Returns an [Iterable<bool>]
  /// based on the result of each transactions which equals the length of the passed list of [hashCodes].
  Iterable<bool> removeListenersByHashCodes(Iterable<int> hashCodes) =>
      _isNotDisposed
          ? hashCodes?.map(_removeListenerByHashCode)?.toList()
          : null;

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

  // bool get _isDisposed => !_isNotDisposed;
  operator -(_) {
    if (_ == null) return null;
    if (_ is Iterable<Notifier>)
      return clone(this)..removeListeners(_._listeners);
    if (_ is Widget) return NotifiableChild(notifier: this, child: _);
    if (_ is WidgetBuilder)
      return SimpleNotificationBuilder(notifier: this, builder: _);
    if (_ is Function())
      return SimpleNotificationBuilder(notifier: this, builder: (c) => _());
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
      debugPrint("Notifier#${this.hashCode}: An error was thrown while specifically notifying the listener#$hashCode (String rep.:$_)");
      rethrow;
    }
    return true;
  }

  Iterable<bool> notifyByHashCodes(Iterable<int> hashCodes) =>
      _isNotDisposed ? _notifyByHashCodes(hashCodes) : null;

  Iterable<bool> _notifyByHashCodes(Iterable<int> hashCodes) =>
      hashCodes?.map(_notifyByHashCode)?.toList();

  int get numberOfListeners => _listeners.length;

  String toString() =>
      "{\"id\": $hashCode, \"Number of Listeners\": ${_listeners.length}}";

  static Notifier merge([Iterable<Notifier> notifiers, bool Function(dynamic) removeListenerOnError]) =>
      notifiers == null ? Notifier._() : notifiers.merge(const [],removeListenerOnError);

  static Notifier from(Notifier notifier) {
    if (notifier.isDisposed)
      throw ArgumentError(
          """A disposed Notifier cannot be cloned!\nPlease make sure you clone it before disposing it, as a disposed Notifier
    loses track of it's listeners, once it's disposed.""");
    return Notifier(removeListenerOnError: notifier._handleError).._listeners = List.from(notifier._listeners);
  }

  static Notifier Function(Notifier) clone = from;

  /// Print this [Notifier]'s details in-line while testing with the help of (..) operator
  void get printMe => print(toString());

  /// Locks the listeners of the current [Notifier] and prevents anyone from adding a listener to it. (by any means)
  ///
  /// If the listeners are already locked, it returns false else it locks the listeners and returns true.
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
  /// If the listeners are already locked, it returns false else it locks the listeners and returns true.
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

  bool get listenersAreUnlocked => !listenersAreLocked;

  Iterator<Notifier> get iterator => {this}.iterator;
  Iterable<Function> get listeners => List.from(_listeners);
}

extension CallableList on Iterable<Function()> {
  Iterable call() => map((_) => _()).toList();
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

  Notifier merge([Iterable<Notifier> notifiers, bool Function(dynamic) removeListenerOnError]){
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

class ValNotifier<T> extends Notifier {

  T _val;

  ValNotifier({
    T initialVal,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Error) removeListenerOnError,
  }) : _val=initialVal, super(attachNotifiers: attachNotifiers,
            listenToNotifiers: listenToNotifiers,
            mergeNotifiers: mergeNotifiers,
            initialListeners: initialListeners,
            removeListenerOnError: removeListenerOnError);

  ValNotifier._();

  T get val => _val;

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
        if(tween==null) throw UnsupportedError("The $runtimeType#$hashCode could not perform the tween $tween. Make sure you use an custom class that extends Tween<$T> and has overriden the transform method in an expected manner. The plugin has added support to directly convert a raw Tween instance to an appropriate one (if supported by the SDK), but it unfortunately couldn't find one for the current type $T. If you have implemented a custom class from your end then please");
      }

      return _performTween(tween, duration, loop: loop, reverse: reverse, curve: curve).then((t){
        t.dispose();
        return this;
      });
    }

    return null;
  }

  Future<Ticker> _performTween(Tween<T> tween, Duration duration, {int loop=1, bool reverse=false, Curve curve = Curves.linear, Ticker t}) async {

    if(t==null)
    t = (reverse ?? false) ? Ticker((d) {
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

    loop = _times(loop);

    WidgetsFlutterBinding.ensureInitialized();
    while(loop--!=0) await t.start();
    return t;

  }

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

      t1 = reverse ? Ticker((d) {
        if (d > duration) {
          call(tween.end);
          return t1..stop();
        }
        return call(tween.transform(firstCurve.transform(d.inMilliseconds / duration.inMilliseconds)));
      }) : Ticker((d) {
        if (d > duration) {
          call(tween.begin);
          return t1..stop();
        }
        return call(tween.transform(1 - firstCurve.transform(d.inMilliseconds / duration.inMilliseconds)));
      });

      t2 = reverse ? Ticker((d) {
        if (d > duration) {
          call(tween.begin);
          return t2..stop();
        }
        return call(tween.transform(1 - secondCurve.transform(d.inMilliseconds / duration.inMilliseconds)));
      }) : Ticker((d) {
        if (d > duration) {
          call(tween.end);
          return t2..stop();
        }
        return call(tween.transform(secondCurve.transform(d.inMilliseconds / duration.inMilliseconds)));
      });


      return Future.doWhile(() async {
        await _performTween(tween, duration, t: t1);
        await _performTween(tween, duration, t: t2);
        return --circles!=0;
      }).then((_){
        t1.dispose();
        t2.dispose();
        return this;
      });
    }
    return null;
  }

  int _times(int times) {
    if(times==null||times==0) return 1;
    return times.abs();
  }

  Future<ValNotifier<T>> interpolateR(Iterable<T> values, Duration totalDuration, {int loop=1, bool reverse=false, Curve curve = Curves.linear, Iterable<Curve> curves}) async {
    if(_isNotDisposed){
      if(T==dynamic) debugPrint("Calling interpolateR on a ValNotifier<dynamic> might be an bad idea.\n"
          "Please try being more specific while specifying the type of variable that holds the ValNotifier().");
      return interpolate(Tween<T>(),values, totalDuration, loop: loop, reverse: reverse, curve: curve, curves: curves);
    }
    return null;
  }

  Future<ValNotifier<T>> interpolate(Tween<T> tween, Iterable<T> values, Duration totalDuration, {int loop=1, bool reverse=false, Curve curve = Curves.linear, Iterable<Curve> curves}) async {
    if(_isNotDisposed){

      assert(tween!=null,"You cannot interpolate across values without a buffer Tween.");
      assert(values!=null,"The parameter values cannot be set to null.");
      assert(totalDuration!=null,"The total duration of the interpolation cannot be set to null.");
      assert((curves==null)!=(curve==null),"Please either set curve or curves in order to interpolate.");
      if(curves==null) curves = List.filled(values.length-1, curve);
      assert(curves.length+1==values.length,"There should be a curve for each interpolation in order to interpolate");
      assert(values.length>1,"We need at least two values to successfully interpolate.");

      try{
        tween.transform(0.5);
      } catch(e){
        tween = _transform(tween);
        if(tween==null) throw UnsupportedError("The $runtimeType#$hashCode could not perform the tween $tween. Make sure you use an custom class that extends Tween<$T> and has overriden the transform method in an expected manner. The plugin has added support to directly convert a raw Tween instance to an appropriate one (if supported by the SDK), but it unfortunately couldn't find one for the current type $T. If you have implemented a custom class from your end then please");
      }

      loop = _times(loop);
      totalDuration~/=curves.length;

      if(reverse??=false){
        values = values.toList().reversed;
        curves = curves.toList().reversed;
      }

      int i;
      tween.begin = values.first;
      tween.end = values[1];

      Ticker t;
      t = reverse ? Ticker((d){
        if (d > totalDuration) {
          call(tween.end);
          t.stop();
          if(++i==values.length) return t;
          tween.begin = tween.end;
          tween.end = values[i];
          curve = curves[i-1];
          return t..start();
        }
        return call(tween.transform(curve.transform(d.inMilliseconds / totalDuration.inMilliseconds)));
      }) :
      Ticker((d){
        if (d > totalDuration) {
          call(tween.begin);
          t.stop();
          if(++i==values.length) return t;
          tween.begin = tween.end;
          tween.end = values[i];
          curve = curves[i-1];
          return t..start();
        }
        return call(tween.transform(1 - curve.transform(d.inMilliseconds / totalDuration.inMilliseconds)));
      });

      return Future.doWhile(() async {
        i = 1;
        await t.start();
        t.stop();
        return --loop!=0;
      }).then((_){
        t.dispose();
        return this;
      });
    }
    return null;
  }

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


  ValNotifier<T> call([covariant T val, bool save = true]) {
    if (val == null) val = this._val;
    if (_isNotDisposed) {
      for (int i = 0; i < _listeners.length; i++) {
        try {
          _listeners[i] is Function(T) ? _listeners[i](val) : _listeners[i]();
        } catch (e) {
          if (_handleError == null) rethrow;
          bool _ = _handleError(e);
          if (_ == null) rethrow;
          if (_) _listeners.removeAt(i--);
        }
      }
      if (save) _val = val;
      return this;
    }
    return null;
  }


  /// Attach a Stream to this [ValNotifier].
  bool attachStream(covariant StreamController<T> s) => _isNotDisposed?addListener(s.add)!=null:null;

  /// Detach a Stream that was previously attached to this [ValNotifier].
  bool detachStream(covariant StreamController<T> s) => _isNotDisposed?removeListener(s.add):null;

  /// Makes the [ValNotifier] listen to an existing stream.
  StreamSubscription<T> listenTo(covariant Stream<T> stream) => stream.listen(this);

  ValNotifier<T> nullNotify() => this(_val = null);

  ValNotifier<T> operator ~() => notify();
  ValNotifier<T> get notify => super.notify;
  ValNotifier<T> get notifyListeners => super.notifyListeners;
  ValNotifier<T> get sendNotification => super.sendNotification;

  operator -(_) {
    if (_ is Notifier) return Notifier.merge([this, _]);
    if (_ is ValNotifier<T>) return ValNotifier.merge<T>([this, _]);
    if (_ is Function())
      return NotificationBuilder(notifier: this, builder: (c) => _());
    if (_ is Function(T))
      return NotificationBuilder(notifier: this, builder: (c) => _(_val));
    if (_ is Function(BuildContext, T))
      return NotificationBuilder(notifier: this, builder: (c) => _(c, _val));
    if (_ is Widget) return NotifiableChild(notifier: this, child: _);
    throw UnsupportedError(
        "$runtimeType<$T>#$hashCode: $runtimeType<$T>'s operator - does not support ${_.runtimeType}.");
  }

  bool init({
    T initialVal,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Error) removeListenerOnError,
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
    bool Function(Error) removeListenerOnError,
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
    bool Function(Error) removeListenerOnError,
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

  bool start({bool play=true}){
    if(_isNotDisposed){
      if(_t.isActive) return false;
      _t.start();
      _t.muted = play!=true;
      return true;
    }
    return null;
  }

  bool play(){
    if(_isNotDisposed){
      if(_t.muted) {
        _t.muted = false;
        return true;
      }
      return false;
    }
    return null;
  }

  bool pause(){
    if(_isNotDisposed){
      if(_t.muted) return false;
      return _t.muted = true;
    }
    return null;
  }

  bool stop() {
    if(_isNotDisposed){
      if(_t.isActive) {
        _t.stop();
        return true;
      }
      return false;
    }
    return null;
  }

  bool dispose() {
    if(super.dispose()){
      _t.stop(canceled: true);
      _t.dispose();
      _t = null;
    }
    return false;
  }

  TickerNotifier({
    bool tickOnStart = false,
    bool muteOnStart = false,
    String debugLabel,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Error) removeListenerOnError,
  }) : super(
    attachNotifiers: attachNotifiers,
    listenToNotifiers: listenToNotifiers,
    mergeNotifiers: mergeNotifiers,
    initialListeners: initialListeners,
    removeListenerOnError: removeListenerOnError,
  ) {
    _t = Ticker((_)=>this(), debugLabel: debugLabel);
    WidgetsFlutterBinding.ensureInitialized();
    start(play: tickOnStart);
    _t.muted = muteOnStart;
  }
}

// Had tried using mixin but an error occurred since multiple signatures of the method call was
// found by the VM.
// So the idea was dropped. call([dynamic]) call([T,`bool`])

class TickerValNotifier<T> extends ValNotifier<T>
{
  Ticker _t;

  bool start({bool pause=false}) {
    if(_isNotDisposed){
      if(_t.isActive) return false;
      _t.start();
      _t.muted = pause==true;
      return true;
    }
    return null;
  }

  bool play(){
    if(_isNotDisposed){
      if(_t.muted) {
        _t.muted = false;
        return true;
      }
      return false;
    }
    return null;
  }

  bool pause(){
    if(_isNotDisposed){
      if(_t.muted) return false;
      return _t.muted = true;
    }
    return null;
  }

  bool stop() {
    if(_isNotDisposed){
      if(_t.isActive) {
        _t.stop();
        return true;
      }
      return false;
    }
    return null;
  }

  bool dispose() {
    if(super.dispose()){
      _t.stop(canceled: true);
      _t.dispose();
      _t = null;
    }
    return false;
  }

  TickerValNotifier({
    T initialVal,
    bool startOnInit = true,
    bool muteOnStart = false,
    String debugLabel,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Error) removeListenerOnError,
  }) : super(
    initialVal: initialVal,
    attachNotifiers: attachNotifiers,
    listenToNotifiers: listenToNotifiers,
    mergeNotifiers: mergeNotifiers,
    initialListeners: initialListeners,
    removeListenerOnError: removeListenerOnError
  ) {
    _t = Ticker((_)=>this(), debugLabel: debugLabel);
    WidgetsFlutterBinding.ensureInitialized();
    if(startOnInit) start(pause: muteOnStart);
    else _t.muted = muteOnStart==true;
  }

  bool init({
        T initialVal,
        bool startOnInit = true,
        bool muteOnStart = false,
        String debugLabel,
        Iterable<Notifier> attachNotifiers,
        Iterable<Function> initialListeners,
        Iterable<Notifier> listenToNotifiers,
        Iterable<Notifier> mergeNotifiers,
        bool Function(Error) removeListenerOnError}
      ){
    if(super.init(
      initialVal: initialVal,
      attachNotifiers: attachNotifiers,
      initialListeners: initialListeners,
      mergeNotifiers: mergeNotifiers,
      removeListenerOnError: removeListenerOnError,
    )){
      _t = Ticker((_)=>this(), debugLabel: debugLabel);
      if(startOnInit) start(pause: muteOnStart);
      else _t.muted = muteOnStart==true;
    }
    return false;
    }
}

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

class TweenNotifier<T> extends ValNotifier<T>
{

  Ticker _t;

  TweenNotifier({
    T initialVal,
    Iterable<Tween<T>> performTweens,
    Iterable<Tween<T>> performCircularTween,
    Duration duration,
    String debugLabel,
    Iterable<Notifier> attachNotifiers,
    Iterable<Notifier> listenToNotifiers,
    Iterable<Notifier> mergeNotifiers,
    Iterable<Function> initialListeners,
    bool Function(Error) removeListenerOnError,
  }) : assert((performTweens==null)==(duration==null),"Please ensure that both performTweens are either either initialized with some expected value, or simply are not."),
        super(
          initialVal: initialVal,
      attachNotifiers: attachNotifiers,
      listenToNotifiers: listenToNotifiers,
      mergeNotifiers: mergeNotifiers,
      initialListeners: initialListeners,
      removeListenerOnError: removeListenerOnError)
  {
    WidgetsFlutterBinding.ensureInitialized();
    if(performTweens!=null) this.performTweens(performTweens, duration);
  }

  bool play(){
    if(_isNotDisposed){
      if(_t.muted) {
        _t.muted = false;
        return true;
      }
      return false;
    }
    return null;
  }

  bool pause(){
    if(_isNotDisposed){
      if(_t.muted) return false;
      return _t.muted = true;
    }
    return null;
  }

  bool dispose() {
    if(super.dispose()){
      _t.stop(canceled: true);
      _t.dispose();
      _t = null;
    }
    return false;
  }

  bool get isPerformingTween => _isNotDisposed?(_t!=null && _t.isTicking):null;
  bool get isNotPerformingTween => _isNotDisposed?(_t==null || !_t.isTicking):null;

  bool get hasPerformedATween => _isNotDisposed?_t!=null:null;
  bool get hasNotPerformedATween => _isNotDisposed?_t==null:null;

  bool get isPaused => _isNotDisposed&&_t!=null&&_t.isActive?_t.muted:null;
  bool get isPlaying => _isNotDisposed&&_t!=null&&_t.isActive?!_t.muted:null;

  // bool get _isNotDisposed {
  //   if(super._isNotDisposed){
  //     if(_t?.isActive ?? false) throw StateError("A TweenNotifier cannot perform more than one controllable animation. Please wait for the current animation to get over.");
  //     return true;
  //   }
  //   return false;
  // }

  Future<TweenNotifier<T>> performTween(Tween<T> tween, Duration duration, {int loop=1, bool reverse=false, Curve curve = Curves.linear}) async {

    if(_isNotDisposed){
      if(_t?.isActive ?? false) throw StateError("A TweenNotifier cannot perform more than one controllable animation. Please wait for the current animation to get over.");
      return super.performTween(tween, duration, loop: loop, reverse: reverse, curve: curve).then((value) => this);
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

  int _times(int times) {
    if(times==null||times==0) return 1;
    return times.abs();
  }

  Future<TweenNotifier<T>> interpolate(Tween<T> tween, Iterable<T> values, Duration totalDuration, {int loop=1, bool reverse=false, Curve curve = Curves.linear, Iterable<Curve> curves}) async {
    if(_isNotDisposed){
      if(_t?.isActive ?? false) throw StateError("A TweenNotifier cannot perform more than one controllable animation. Please wait for the current animation to get over.");
      return super.interpolate(tween, values, totalDuration, loop: loop, reverse: reverse, curve: curve, curves: curves).then((value) => this);
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

  Future<Ticker> _performTween(Tween<T> tween, Duration duration, {int loop=1, bool reverse=false, Curve curve = Curves.linear, Ticker t}) async {

    if(t==null)
      t = (reverse ?? false) ? Ticker((d) {
        if (d > duration) {
          call(tween.begin);
          return _t..stop();
        }
        return call(tween.transform(1 - curve.transform(d.inMilliseconds / duration.inMilliseconds)));
      }) : Ticker((d) {
        if (d > duration) {
          call(tween.end);
          return _t..stop();
        }
        return call(tween.transform(curve.transform(d.inMilliseconds / duration.inMilliseconds)));
      });

    loop = _times(loop);
    _t = t;
    WidgetsFlutterBinding.ensureInitialized();
    while(loop--!=0) await _t.start();
    return _t;
  }

}

extension Iterable_ValNotifier<T> on Iterable<ValNotifier<T>> {
  Iterable<ValNotifier<T>> nullNotify() => map((n)=>n?.nullNotify()).toList();
  ValNotifier<T> merge([Iterable<ValNotifier<T>> notifiers]) => ValNotifier<T>._().._addListeners(_listeners).._addListeners(notifiers._listeners);
}