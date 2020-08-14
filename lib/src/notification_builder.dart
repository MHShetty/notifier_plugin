part of notifier_plugin;

/// NotifiableChild Widget
class NotifiableChild extends StatefulWidget {
  final Iterable<Notifier> notifier;
  final Widget child;

  NotifiableChild({@required this.notifier, @required this.child});

  @override
  _NotifiableChildState createState() => _NotifiableChildState();
}

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

/// SimpleNotificationBuilder widget
class SimpleNotificationBuilder extends StatefulWidget {
  final Iterable<Notifier> notifier;
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
/// NotificationBuilder widget

class NotificationBuilder extends StatefulWidget {

  final Iterable<Notifier> notifier;
  final Widget Function(BuildContext) builder;
  final bool disposeNotifier;
  final bool Function() canRebuild;

  const NotificationBuilder({
    @required this.notifier,
    @required this.builder,
    this.canRebuild,
    this.disposeNotifier,
    Key key
  })
      :
        assert(notifier != null),
        assert(builder != null),
        super(key: key);

  createState() => _NotificationBuilderState();
}

class _NotificationBuilderState extends State<NotificationBuilder> {

  void initState() {
    super.initState();
    widget.notifier.undisposedNotifiers.addListener(this._setState);
  }

  void dispose() {
    widget.notifier.removeListener(this._setState);
    if (widget.disposeNotifier != null && widget.disposeNotifier) widget
        .notifier.dispose();
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

/// MultiNotificationBuilder widget
class MultiNotificationBuilder extends StatefulWidget {

  final Iterable<Notifier> notifier;
  final Widget Function(BuildContext, Notifier) builder;
  final bool disposeNotifier;
  final bool Function() canRebuild;

  const MultiNotificationBuilder({
    @required this.notifier,
    @required this.builder,
    this.canRebuild,
    this.disposeNotifier,
    Key key})
      :
    assert(notifier != null),
    assert(builder != null),
    super(key: key);

  createState() => _MultiNotificationBuilderState();
}

class _MultiNotificationBuilderState extends State<MultiNotificationBuilder> {

  List<Notifier> notifiers = [];
  Notifier _;

  Notifier pop() {
    if (notifiers.isEmpty) return null;
    _ = notifiers.last;
    notifiers.removeLast();
    return _;
  }

  void initState() {
    super.initState();
    widget.notifier.undisposedNotifiers.addListener(this._setState);
  }

  void dispose() {
    widget.notifier.removeListener(this._setState);
    if (widget.disposeNotifier != null && widget.disposeNotifier) widget
        .notifier.dispose();
    notifiers = null;
    super.dispose();
  }

  void didUpdateWidget(MultiNotificationBuilder oldWidget) {
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(this._setState);
      widget.notifier.addListener(this._setState);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _setState() => (mounted && (widget.canRebuild == null || widget.canRebuild() ?? false)) ? setState(() {}) : null;
  Widget build(BuildContext context) => widget.builder(context, pop());
}

/// ValNotificationBuilder<T> widget
class ValNotificationBuilder<T> extends StatefulWidget {
  final ValNotifier<T> notifier;
  final Widget Function(BuildContext, T val) builder;
  final bool disposeNotifier;
  final bool Function(T val) canRebuild;

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
    widget.notifier.undisposedNotifiers.addListener(this._setState);
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

/// Extensions to add syntactic sugar while using the above widgets
extension Notifiable__Widget on Widget Function(BuildContext) {
  operator -(Iterable<Notifier> notifier) => SimpleNotificationBuilder(notifier: notifier, builder: this);
}

extension Temp_Notifier on Widget Function(Notifier) {
  Widget operator ~() {
    Notifier notifier = Notifier();
    return NotificationBuilder(
        notifier: notifier, builder: (c) => this(notifier));
  }
}

extension Temp_ValNotifier<T> on Widget Function(ValNotifier<T>,T){
  Widget operator ~(){
    ValNotifier<T> valNotifier = ValNotifier<T>();
    return SimpleNotificationBuilder(notifier: valNotifier, builder: (c)=>this(valNotifier,valNotifier.val));
  }
}

extension Notifiable_Widget on Widget {
  operator -(Iterable<Notifier> notifier) =>
      NotifiableChild(notifier: notifier, child: this);
}