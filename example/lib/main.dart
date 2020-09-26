import 'package:flutter/material.dart';
import 'menu.dart';
import 'storage.dart';
import 'examples/notifier.dart';
import 'examples/valnotifier.dart';
import 'examples/tweennotifier.dart';
import 'examples/httpnotifier.dart';
import 'examples/swnotifier.dart';
import 'examples/timednotifier.dart';

void main() {
  runApp(ExampleApp());
  loadRes();
}

class ExampleApp extends StatelessWidget with WidgetsBindingObserver {

  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: "main",
      builder: (_,c) => ScrollConfiguration(behavior: GlowFree(), child: c),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [NavigatorObserver()],
      routes: {
        "main": (c) => MenuScreen(),
        "notifier": (c) => NotifierExample(),
        "valNotifier": (c) => ValNotifierExample(),
        "tweenNotifier": (c) => TweenNotifierExample(),
        "httpNotifier": (c) => HttpNotifierExample(),
        "timedNotifier": (c) => TimedNotifierExample(),
        "swNotifier": (c) => SWNotifierExample(),
      },
    );
  }

}

class GlowFree extends ScrollBehavior {buildViewportChrome(_,c,__) => c;}





//  Widget build(BuildContext context) {
//
//    print(timedNotifier.isActive);
//
//    return MaterialApp(
//      home: Scaffold(
//        body: Center(
//          child: timedNotifier - (v) => Column(
//            mainAxisAlignment: MainAxisAlignment.center,
//            children: [
//              Text(timedNotifier.ticks.toString()),
//              Text(timedNotifier.ticks.toString()),
//              Text(timedNotifier.ticks.toString()),
//              RaisedButton(
//                onPressed: ()=>timedNotifier.isPaused?timedNotifier.play():timedNotifier.pause(),
//                child: Text(""),
//              )
//            ],
//          ),
//        ),
//      ),
//    );
//
//  }
//}
/*
class TestScaffold1 extends StatefulWidget {
  @override
  _TestScaffold1State createState() => _TestScaffold1State();
}

class _TestScaffold1State extends State<TestScaffold1> {

  HttpNotifier httpNotifier;

  void initState() {
    super.initState();
    httpNotifier = HttpNotifier.read(url: "https://www.google.com", initialVal: "", parseResponse: (r){});
    httpNotifier.addListener(print);
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            TextField(
                onSubmitted: (url) async {
              try {
                url = url.replaceAll(' ', '');
                if (!(url.startsWith("https://") || url.startsWith("https://"))) url = "https://$url";
                print(url);
                await httpNotifier.get(url: url);
              } catch (e) {
                print(e.toString());
                httpNotifier("Invalid URL");
              }
            }),
            httpNotifier -
                (v) => Expanded(
                    child: httpNotifier.isSyncing
                        ? SizedBox(height: 16.0, width: 16.0)
                        : Center(child: SingleChildScrollView(child: Text(v.toString())))),
            RaisedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text("Refresh"),
              onPressed: httpNotifier.readBytes,
            )
          ],
        ),
      ),
    );
  }
}

class TestScaffold0 extends StatefulWidget
{
  _TestScaffoldState0 createState() => _TestScaffoldState0();
}

class _TestScaffoldState0 extends State<TestScaffold0> with TickerProviderStateMixin {
  Notifier test;
  ValNotifier<Color> valTest;
  double a = 0;

  void initState() {
    super.initState();
    test = Notifier();
    valTest = ValNotifier<Color>();
  }

  Widget build(BuildContext context) {

    return valTest -
        () => Scaffold(
            backgroundColor: valTest.val,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ~(n, v) => GestureDetector(
                        onHorizontalDragUpdate: (d) => n(d.localPosition.dx),
                        child: Container(
                          height: 200,
                          width: 200,
//                  margin: EdgeInsets.only(left: a.abs()),
                          decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(100),
                              border:
                                  Border.all(color: Colors.white, width: 4.0)),
                          alignment: Alignment.center,
                          child: Text(
                            v.toString(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  const SizedBox(
                    height: 12,
                  ),
                  RaisedButton(
                    child: Text("Animate"),
                    onPressed: () {
                      print("Animation started!");
                      valTest.performTween(ColorTween(begin: Colors.red, end: Colors.green), Duration(seconds: 1)).then((value) => print("Animation completed!"));
                    },
                  )
                ],
              ),
            ));
  }
}

*/