part of notifier_plugin;

class WFuture<T> {
  final Future<T> future;
  Widget Function() onLoading;
  Widget Function(dynamic) onError;

  WFuture(this.future, {this.onLoading, this.onError});

  FutureBuilder<T> operator -(Widget Function(T) onData) => FutureBuilder<T>(
        future: future,
        builder: (c, s) {
          if (s.hasData) return onData(s.data);
          if (s.hasError) if (onError == null) {
            debugPrint(s.error.toString());
            return Center(
                child: Text(s.error.toString(),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center));
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

class WStream<T> {
  final Stream<T> stream;
  Widget Function() onLoading;
  Widget Function(dynamic) onError;

  WStream(this.stream, {this.onLoading, this.onError});

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
      FutureBuilder<T>(
        future: this,
        builder: (c, s) => builder(s),
      );
}

extension Future_Function_Ease<T> on Future<T> Function() {
  FutureBuilder<T> operator -(Widget Function(AsyncSnapshot<T>) builder) =>
      FutureBuilder<T>(
        future: this(),
        builder: (c, s) => builder(s),
      );
}

extension Stream_Ease<T> on Stream<T> {
  StreamBuilder<T> operator -(Widget Function(AsyncSnapshot<T>) builder) =>
      StreamBuilder<T>(
        stream: this,
        builder: (c, s) => builder(s),
      );
}

extension StreamController_Ease<T> on StreamController<T> {
  StreamBuilder<T> operator -(Widget Function(AsyncSnapshot<T>) builder) =>
      StreamBuilder<T>(
        stream: stream,
        builder: (c, s) => builder(s),
      );
}

extension Stream_Function_Ease<T> on Stream<T> Function() {
  StreamBuilder<T> operator -(Widget Function(AsyncSnapshot<T>) builder) =>
      StreamBuilder<T>(
        stream: this(),
        builder: (c, s) => builder(s),
      );
}

extension ChangeNotifier_Ease on ChangeNotifier {
  ChangeNotifierBuilder operator -(Widget Function() builder) =>
      ChangeNotifierBuilder(
        changeNotifier: this,
        builder: (c) => builder(),
      );
}

extension Iterable_ChangeNotifier_Ease on Iterable<ChangeNotifier> {
  MultiChangeNotifierBuilder operator -(Widget Function() builder) =>
      MultiChangeNotifierBuilder(
        changeNotifiers: this,
        builder: (c) => builder(),
      );
}

extension ValueNotifier_Ease<T> on ValueNotifier<T> {

  ChangeNotifierBuilder operator -(Widget Function(T) builder) =>
      ChangeNotifierBuilder(
        changeNotifier: this,
        builder: (c) => builder(value),
      );
}

// extension Iterable_ValueNotifier_Ease<T> on Iterable<ValueNotifier<T>>
// {
//   MultiChangeNotifierBuilder operator-(Widget Function(T) builder) => MultiChangeNotifierBuilder(
//     changeNotifiers: this,
//     builder: (c)=>builder(),
//   );
// }

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

extension ChangeNotifier_Extension on ChangeNotifier
{
  ChangeNotifier call([dynamic value]){
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    notifyListeners();
    return this;
  }
}

extension ValueNotifier_Extension<T> on ValueNotifier<T>
{
  ChangeNotifier call([T value,bool save=true]){
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    if(value==null) notifyListeners();
    else {
      T _ = this.value;
      this.value = value;
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      notifyListeners();
      if(!(save??true)) this.value = _;
    }
    return this;
  }
}

extension IterableChangeNotifier_Extension on Iterable<ChangeNotifier>
{
  Iterable<ChangeNotifier> call([dynamic value]){
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    forEach((cn)=>cn());
    return this;
  }

  /// Adds a [listener] to all the [ChangeNotifier]s.
  ///
  /// true at any given index just means that that ChangeNotifier was not disposed while performing that
  /// operation.
  Iterable<bool> addListener(void Function() listener) =>
    map((cn) {
      try{
        cn.addListener(listener);
        return true;
      } catch(e){return false;}
    });

  /// Tries to remove the [listener] to all the [ChangeNotifier]s.
  ///
  /// true at any given index just means that that ChangeNotifier was not disposed while performing that
  /// operation.
  Iterable<bool> removeListener(void Function() listener) =>
      map((cn) {
        try{
          cn.removeListener(listener);
          return true;
        } catch(e){return false;}
      });
}

extension IterableValueNotifier_Extension<T> on Iterable<ValueNotifier<T>>
{
  Iterable<ValueNotifier<T>> call([T value,bool save=true]){
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    forEach((cn){cn(value,save);});
    return this;
  }
}