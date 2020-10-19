part of notifier_plugin;

/// [WFuture]<[T]> is a special helper class that enables a developer to define a common loader ([onLoading]), error handler
/// [onError] and the [future] around which everything else is supposed to be wrapped.
///
/// The operator [-] can be used to pass a [Widget] Function([T]) that is called when the future gets/is successfully completed
/// in order to obtain the Widget to be rendered then. The function gets the data with which the [future] was completed. If an
/// error is thrown, the [onError] method is called instead.
class WFuture<T> {
  /// The [Future]<[T]> around which everything else in this class is wrapped.
  final Future<T> future;

  /// The return value of this function would determine the [Widget] to be rendered, until the [future] does not get complete.
  /// (Default: [SmartCircularProgressIndicator])
  Widget Function() onLoading;

  /// This function accepts the error with which the [future] was completed and the return value determines the [Widget] to be
  /// rendered if the [future] completes with an error. (Default: A [Text] widget that renders the string representation of the
  /// error that was obtained, when the future was complete)
  Widget Function(dynamic) onError;

  /// A constructor that instantiates a [WFuture]<[T]>.
  WFuture(this.future, {this.onLoading, this.onError});

  /// The operator [-] can be used to pass a '[Widget] Function([T])' that is called when the future gets/is successfully completed
  /// in order to obtain the Widget to be rendered then. The function gets the data with which the [future] was completed. If an
  /// error is thrown, the [onError] method is called instead.
  FutureBuilder<T> operator -(Widget Function(T) onData) => FutureBuilder<T>(
        future: future,
        builder: (c, s) {
          if (s.hasData) return onData(s.data);
          if (s.hasError) if (onError == null) {
            debugPrint(s.error.toString());
            return Center(
              child: Text(s.error.toString(),
                  overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            );
          } else
            return onError(s.error) ??
                Center(
                    child: Text(s.error.toString(),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center));
          return onLoading == null
              ? const SmartCircularProgressIndicator()
              : onLoading() ?? const SmartCircularProgressIndicator();
        },
      );
}

/// [WStream]<[T]> is a special helper class that enables the developer to easily design UI that depends on a Stream to be more
/// dynamic or to be in-sync with some data/state in real-time. The return value of the [onLoading] method determines the widget
/// to be rendered when the stream is loading and the return value of the [onError] method after passing the error obtained
/// determines the widget to be rendered when the Stream receives an error. The widget to be rendered when a piece of data is
/// normally received is determined by the [Widget] Function([T]) passed to the [operator -] that determines the widget to be
/// rendered.
class WStream<T> {
  /// Stores the stream that is wrapped by this class
  final Stream<T> stream;

  /// The return value of the function determines the widget to rendered when the stream is loading or does not have data.
  Widget Function() onLoading;

  /// The return value of the function determines the widget to rendered when the stream receives the an error.
  Widget Function(dynamic) onError;

  /// A constructor that instantiates a [WStream]<[T]>
  WStream(this.stream, {this.onLoading, this.onError});

  /// The operator [-] can be used to pass a '[Widget] Function([T])' that is called when the stream receives an data of type
  /// [T]. The received data is then passed to [onData] function in order to obtain the Widget to be rendered. If an error is
  /// received, then the [onError] method is called instead, by passing the received error.
  StreamBuilder<T> operator -(Widget Function(T) onData) => StreamBuilder<T>(
        stream: stream,
        builder: (c, s) {
          if (s.hasData) return onData(s.data);
          if (s.hasError) if (onError == null) {
            debugPrint(s.error.toString());
            return Text(s.error.toString(), overflow: TextOverflow.ellipsis);
          } else
            return onError(s.error) ??
                Text(s.error.toString(), overflow: TextOverflow.ellipsis);
          return onLoading == null
              ? const SmartCircularProgressIndicator()
              : onLoading() ?? const SmartCircularProgressIndicator();
        },
      );
}

extension Future_Ease<T> on Future<T> {
  FutureBuilder<T> operator -(Widget Function(AsyncSnapshot<T>) builder) =>
      FutureBuilder<T>(future: this, builder: (c, s) => builder(s));
}

extension Future_Function_Ease<T> on Future<T> Function() {
  FutureBuilder<T> operator -(Widget Function(AsyncSnapshot<T>) builder) =>
      FutureBuilder<T>(future: this(), builder: (c, s) => builder(s));
}

extension Stream_Ease<T> on Stream<T> {
  StreamBuilder<T> operator -(Widget Function(AsyncSnapshot<T>) builder) =>
      StreamBuilder<T>(stream: this, builder: (c, s) => builder(s));
}

extension StreamController_Ease<T> on StreamController<T> {
  StreamBuilder<T> operator -(Widget Function(AsyncSnapshot<T>) builder) =>
      StreamBuilder<T>(stream: stream, builder: (c, s) => builder(s));
}

extension Stream_Function_Ease<T> on Stream<T> Function() {
  StreamBuilder<T> operator -(Widget Function(AsyncSnapshot<T>) builder) =>
      StreamBuilder<T>(stream: this(), builder: (c, s) => builder(s));
}

extension ChangeNotifier_Ease on ChangeNotifier {
  ChangeNotifierBuilder operator -(Widget Function() builder) =>
      ChangeNotifierBuilder(changeNotifier: this, builder: (c) => builder());
}

extension Iterable_ChangeNotifier_Ease on Iterable<ChangeNotifier> {
  MultiChangeNotifierBuilder operator -(Widget Function() builder) =>
      MultiChangeNotifierBuilder(
          changeNotifiers: this, builder: (c) => builder());
}

extension ValueNotifier_Ease<T> on ValueNotifier<T> {
  ChangeNotifierBuilder operator -(Widget Function(T) builder) =>
      ChangeNotifierBuilder(
          changeNotifier: this, builder: (c) => builder(value));
}

class ChangeNotifierBuilder extends StatefulWidget {
  final ChangeNotifier changeNotifier;
  final WidgetBuilder builder;

  ChangeNotifierBuilder({this.changeNotifier, this.builder});

  _ChangeNotifierBuilderState createState() => _ChangeNotifierBuilderState();
}

class _ChangeNotifierBuilderState extends State<ChangeNotifierBuilder> {
  void initState() {
    super.initState();
    widget.changeNotifier.addListener(_setState);
  }

  void dispose() {
    widget.changeNotifier.removeListener(_setState);
    super.dispose();
  }

  void didUpdateWidget(ChangeNotifierBuilder oldWidget) {
    if (oldWidget.changeNotifier != widget.changeNotifier) {
      oldWidget.changeNotifier.removeListener(_setState);
      widget.changeNotifier.addListener(_setState);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _setState() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

class MultiChangeNotifierBuilder extends StatefulWidget {
  final Iterable<ChangeNotifier> changeNotifiers;
  final WidgetBuilder builder;

  MultiChangeNotifierBuilder({this.changeNotifiers, this.builder});

  _MultiChangeNotifierBuilderState createState() =>
      _MultiChangeNotifierBuilderState();
}

class _MultiChangeNotifierBuilderState
    extends State<MultiChangeNotifierBuilder> {
  void initState() {
    super.initState();
    widget.changeNotifiers
        .forEach((changeNotifier) => changeNotifier.addListener(_setState));
  }

  void dispose() {
    widget.changeNotifiers
        .forEach((changeNotifier) => changeNotifier.addListener(_setState));
    super.dispose();
  }

  void didUpdateWidget(MultiChangeNotifierBuilder oldWidget) {
    if (oldWidget.changeNotifiers != widget.changeNotifiers) {
      oldWidget.changeNotifiers.forEach(
          (changeNotifier) => changeNotifier.removeListener(_setState));
      widget.changeNotifiers
          .forEach((changeNotifier) => changeNotifier.addListener(_setState));
    }
    super.didUpdateWidget(oldWidget);
  }

  void _setState() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// An extension method that enables the developer to directly call an [ChangeNotifier]
extension ChangeNotifier_Extension on ChangeNotifier {
  ChangeNotifier call([dynamic value]) {
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    notifyListeners();
    return this;
  }
}

/// An extension method that enables the developer to directly call an [ValueNotifier]<[T]>
extension ValueNotifier_Extension<T> on ValueNotifier<T> {
  ChangeNotifier call([T value, bool save = true]) {
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    if (value == null)
      notifyListeners();
    else {
      T _ = this.value;
      this.value = value;
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      notifyListeners();
      if (!(save ?? true)) this.value = _;
    }
    return this;
  }
}

/// An extension method that enables the developer to directly call an [Iterable]<[ChangeNotifier]>
extension IterableChangeNotifier_Extension on Iterable<ChangeNotifier> {
  Iterable<ChangeNotifier> call([dynamic value]) {
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    forEach((cn) => cn());
    return this;
  }

  /// Adds a [listener] to all the [ChangeNotifier]s.
  ///
  /// true at any given index just means that that ChangeNotifier was not disposed while performing that
  /// operation.
  Iterable<bool> addListener(void Function() listener) => map((cn) {
        try {
          cn.addListener(listener);
          return true;
        } catch (e) {
          return false;
        }
      });

  /// Tries to remove the [listener] to all the [ChangeNotifier]s.
  ///
  /// true at any given index just means that that ChangeNotifier was not disposed while performing that
  /// operation.
  Iterable<bool> removeListener(void Function() listener) => map((cn) {
        try {
          cn.removeListener(listener);
          return true;
        } catch (e) {
          return false;
        }
      });
}

/// An extension method that enables the developer to directly call an [Iterable]<[ValueNotifier]<[T]>>
extension IterableValueNotifier_Extension<T> on Iterable<ValueNotifier<T>> {
  Iterable<ValueNotifier<T>> call([T value, bool save = true]) {
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    forEach((cn) {
      cn(value, save);
    });
    return this;
  }
}

/// A [CircularProgressIndicator] that can decently auto-adjust itself with respect to the widget tree it is placed in, and is
/// hence considered to be smart.
class SmartCircularProgressIndicator extends StatelessWidget {
  const SmartCircularProgressIndicator();

  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
