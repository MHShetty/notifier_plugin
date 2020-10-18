import 'package:flutter/material.dart';
import 'menu.dart';
import 'storage.dart';
import 'examples/notifier.dart';
import 'examples/valNotifier.dart';
import 'examples/tweenNotifier.dart';
import 'examples/httpNotifier.dart';
import 'examples/swNotifier.dart';
import 'examples/timedNotifier.dart';

void main() async {
  runApp(ExampleApp());
  loadRes();
}

class ExampleApp extends StatelessWidget with WidgetsBindingObserver {
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: "main",
      builder: (_, context) =>
          ScrollConfiguration(behavior: GlowFree(), child: context),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [NavigatorObserver()],
      routes: {
        "main": (context) => MenuScreen(),
        "notifier": (context) => NotifierExample(),
        "valNotifier": (context) => ValNotifierExample(),
        "tweenNotifier": (context) => TweenNotifierExample(),
        "httpNotifier": (context) => HttpNotifierExample(),
        "timedNotifier": (context) => TimedNotifierExample(),
        "swNotifier": (context) => SWNotifierExample(),
      },
    );
  }
}

class GlowFree extends ScrollBehavior {
  buildViewportChrome(_, context, __) => context;
}
