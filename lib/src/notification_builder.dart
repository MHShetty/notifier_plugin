part of notifier_plugin;

/// NotifiableChild Widget (Might get removed in the future)
@deprecated
class NotifiableChild extends StatefulWidget {

  final Iterable<Notifier> notifier;
  final Widget child;

  NotifiableChild({@required this.notifier, @required this.child});

  @override
  _NotifiableChildState createState() => _NotifiableChildState();
}

@deprecated
class _NotifiableChildState extends State<NotifiableChild> {

  void initState() {
    super.initState();
    widget.notifier.addListener(_setState);
  }

  void dispose() {
    widget.notifier.removeListener(_setState);
    super.dispose();
  }

  void didUpdateWidget(NotifiableChild oldWidget) {
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_setState);
     widget.notifier.addListener(_setState);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _setState() => setState((){});

  Widget build(BuildContext context) => widget.child;
}

/// A [SimpleNotificationBuilder] is a [NotificationBuilder] that is a bit simpler. It only accepts a set of [notifier]s and
/// a [builder] function that executes to return a [Widget] to the main build method of this this widget, whenever it gets
/// re-built either by the notification of one of the [notifier]s or when the widget tree in which it is placed in gets
/// rebuilt.
class SimpleNotificationBuilder extends StatefulWidget {

  /// Accepts a set of [notifier]s whose notification events this [SimpleNotificationBuilder] can listen to.
  final Iterable<Notifier> notifier;

  /// Accepts a [builder] method that returns the widget to be rendered.
  final Widget Function(BuildContext) builder;

  const SimpleNotificationBuilder({this.notifier, this.builder});

  createState() => _SimpleNotificationBuilderState();
}

class _SimpleNotificationBuilderState extends State<SimpleNotificationBuilder> {

  void initState() {
    super.initState();
    widget.notifier.addListener(_setState);
  }

  void dispose() {
    widget.notifier.removeListener(_setState);
    super.dispose();
  }

  void didUpdateWidget(SimpleNotificationBuilder oldWidget) {
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_setState);
      widget.notifier.addListener(_setState);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _setState() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// A (private) lighter version on SimpleNotificationBuilder that automatically disposes it's notifiers
class _NotificationBuilder extends StatefulWidget {

  final Iterable<Notifier> notifier;
  final Widget Function(BuildContext) builder;

  const _NotificationBuilder({this.notifier, this.builder});

  createState() => __NotificationBuilderState();
}

class __NotificationBuilderState extends State<_NotificationBuilder> {

  void initState() {
    super.initState();
    widget.notifier.addListener(_setState);
  }

  void dispose() {
    widget.notifier.removeListener(_setState);
    widget.notifier.dispose();
    super.dispose();
  }

  void didUpdateWidget(_NotificationBuilder oldWidget) {
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_setState);
      widget.notifier.addListener(_setState);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _setState() => setState(() {});

  Widget build(BuildContext context) => widget.builder(context);
}

/// The [NotificationBuilder] widget just simply re-builds the [builder] function passed to it, whenever the [notifier]s
/// passed to it gets called/receives a notification. Optionally, one could decide when the [NotificationBuilder] should
/// re-build on notification and when not by the help of [canRebuild] parameter. The passed [notifier]s can be disposed when
/// this widget gets disposed by passing true to the [disposeNotifier] parameter.
class NotificationBuilder extends StatefulWidget
{
  /// The [notifier]s that can rebuild this widget with the help of the passed [builder] (whenever it/they get(s) notified)
  final Iterable<Notifier> notifier;

  /// The [builder] function that is executed in order to dynamically obtain a (new) widget, whenever this builder widget
  /// gets re-built (either when one of the passed [notifier]s get notified or when the tree in which this widget is placed
  /// gets re-built)
  final Widget Function(BuildContext) builder;

  /// Decides whether the [notifier]s that were passed to this widget should get disposed when this widget gets disposed or not.
  ///
  /// If it is set to true, disposes the the given set of notifiers, else simply doesn't dispose them when this widget gets
  /// disposed.
  final bool disposeNotifier;

  /// The return value of the passed function [canRebuild] decides whether or not this widget should re-build when a notifier
  /// gets notified.
  ///
  /// If it returns true, the widget gets rebuilt on notification else it simply doesn't. If this function is set to null or if
  /// the parameter is not passed it rebuilds by default.
  final bool Function() canRebuild;

  /// A constructor that executes before completely instantiating a [NotificationBuilder].
  const NotificationBuilder({
    @required this.notifier,
    @required this.builder,
    this.canRebuild,
    this.disposeNotifier,
    Key key,
  }) : assert(notifier != null),
       assert(builder != null),
       super(key: key);

  _NotificationBuilderState createState() => _NotificationBuilderState();
}

class _NotificationBuilderState extends State<NotificationBuilder> {

  void initState() {
    super.initState();
    widget.notifier.unDisposedNotifiers.addListener(this._setState);
  }

  void dispose() {
    widget.notifier.removeListener(this._setState);
    if (widget.disposeNotifier==true) widget.notifier.dispose();
    super.dispose();
  }

  void didUpdateWidget(NotificationBuilder oldWidget) {
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(this._setState);
      widget.notifier.addListener(this._setState);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _setState() => (mounted && (widget.canRebuild == null || widget.canRebuild() ?? false)) ? setState(() {}) : null;

  Widget build(BuildContext context) => widget.builder(context);
}

// /// MultiNotificationBuilder widget
// class MultiNotificationBuilder extends StatefulWidget {
//
//   final Iterable<Notifier> notifier;
//   final Widget Function(BuildContext, Notifier) builder;
//   final bool disposeNotifiers;
//   final bool Function() canRebuild;
//
//   const MultiNotificationBuilder({
//     @required this.notifier,
//     @required this.builder,
//     this.canRebuild,
//     this.disposeNotifiers,
//     Key key})
//       :
//     assert(notifier != null),
//     assert(builder != null),
//     super(key: key);
//
//   createState() => _MultiNotificationBuilderState();
// }

// class _MultiNotificationBuilderState extends State<MultiNotificationBuilder> {
//
//   List<Notifier> notifiers = [];
//   Notifier _;
//
//   Notifier pop() {
//     if (notifiers.isEmpty) return null;
//     _ = notifiers.last;
//     notifiers.removeLast();
//     return _;
//   }
//
//   void initState() {
//     super.initState();
//     widget.notifier.unDisposedNotifiers.addListener(this._setState);
//   }
//
//   void dispose() {
//     widget.notifier.removeListener(this._setState);
//     if (widget.disposeNotifiers != null && widget.disposeNotifiers) widget.notifier.dispose();
//     notifiers = null;
//     super.dispose();
//   }
//
//   void didUpdateWidget(MultiNotificationBuilder oldWidget) {
//     if (oldWidget.notifier != widget.notifier) {
//       oldWidget.notifier.removeListener(this._setState);
//       widget.notifier.addListener(this._setState);
//     }
//     super.didUpdateWidget(oldWidget);
//   }
//
//   void _setState() => (mounted && (widget.canRebuild == null || widget.canRebuild() ?? false)) ? setState(() {}) : null;
//
//   Widget build(BuildContext context) => widget.builder(context, pop());
// }

/// A [ValNotificationBuilder]<[T]> accepts a [notifier] of type [ValNotifier]<[T]> and a [builder] function that re-builds
/// either when the notifier gets called or when the widget tree it is a part of gets re-built. One can decide when the
/// widget should re-build and when not by passing a function that accepts a value of type [T] to the parameter [canRebuild]
/// and return true on whichever notification the widget should rebuild else false. Optionally, one can pass true to the
/// to the [disposeNotifier] parameter to dispose the passed [notifier], once this widget gets disposed.
class ValNotificationBuilder<T> extends StatefulWidget {

  /// The [notifier] parameter accepts a [ValNotifier]<[T]> whose changes this [ValNotificationBuilder] listens to in order to
  /// conditionally re-build with the help of the [canRebuild] method.
  final ValNotifier<T> notifier;

  /// The [builder] parameter accepts a method that accepts a [BuildContext] and value of type [T] and returns a widget
  /// that can be returned by the build method of this widget.
  final Widget Function(BuildContext, T) builder;

  /// The [disposeNotifier] parameter accepts a [bool] value that determines whether or not the passed [notifier] should
  /// be disposed when this widget gets disposed.
  final bool disposeNotifier;

  /// The return value of the method [canRebuild] that accepts the most recent value of the passed [notifier] of type [T]
  /// determines whether or not the widget should re-build when the passed [notifier] gets called. If this method returns
  /// true the widget rebuilds on notification, else it doesn't. The widget rebuilds by default, if this parameter doesn't
  /// receive any value or receives null.
  final bool Function(T) canRebuild;

  /// A const constructor that gets called in order to completely instantiate a [ValNotificationBuilder].
  const ValNotificationBuilder({
    @required this.notifier,
    @required this.builder,
    this.canRebuild,
    this.disposeNotifier,
    Key key})
      :
        assert(notifier != null),
        assert(builder != null),
        super(key: key);

  createState() => _ValNotificationBuilderState<T>();
}


class _ValNotificationBuilderState<T> extends State<ValNotificationBuilder<T>> {

  void initState() {
    super.initState();
    widget.notifier.unDisposedNotifiers.addListener(this._setState);
  }

  void dispose() {
    widget.notifier.removeListener(this._setState);
    if (widget.disposeNotifier != null && widget.disposeNotifier) widget
        .notifier.dispose();
    super.dispose();
  }

  void didUpdateWidget(ValNotificationBuilder oldWidget) {
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(this._setState);
      widget.notifier.addListener(this._setState);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _setState() =>
      (mounted && (widget.canRebuild == null ||
          widget.canRebuild(widget.notifier.val) ?? false))
          ? setState(() {})
          : null;

  build(BuildContext context) => widget.builder(context, widget.notifier.val);
}

// Extensions to add syntactic sugar while using the above widgets

/// Enables the developer to use the operator '-' to attach a [Notifier] to a widget.
extension Notifiable_Widget on Widget {
  @deprecated
  NotifiableChild operator -(Iterable<Notifier> notifier) =>NotifiableChild(notifier: notifier, child: this);
}

/// Enables the developer to use the operator '-' to attach a [Notifier] to a WidgetBuilder function.
extension Notifiable__Widget on Widget Function(BuildContext) {
  SimpleNotificationBuilder operator -(Iterable<Notifier> notifier) =>
      SimpleNotificationBuilder(notifier: notifier, builder: this);
}

/// Enables the developer to use the operator '~' to implicitly instantiate and attach the passed [Widget Function(Notifier)] to
/// a [Notifier].
///
/// The instance of the [Notifier] that was implicitly instantiated can be obtained by the first (and only) parameter of the
/// passed function. The returned widget is the widget that needs to be rendered.
extension Temp_Notifier on Widget Function(Notifier) {
  SimpleNotificationBuilder operator ~() {
    Notifier notifier = Notifier();
    return SimpleNotificationBuilder(notifier: notifier, builder: (c) => this(notifier));
  }
}

/// Enables the developer to use the operator '~' to implicitly instantiate and attach the passed [Widget Function(Notifier)] to
/// a [ValNotifier]<[T]>.
///
/// The instance of the [ValNotifier]<[T]> that was implicitly instantiated can be obtained by the first (and only) parameter of the
/// passed function. The returned widget is the widget that needs to be rendered.
extension Temp_ValNotifier<T> on Widget Function(ValNotifier<T>,T){
  SimpleNotificationBuilder operator ~(){
    ValNotifier<T> valNotifier = ValNotifier<T>();
    return SimpleNotificationBuilder(notifier: valNotifier, builder: (c)=>this(valNotifier,valNotifier.val));
  }
}