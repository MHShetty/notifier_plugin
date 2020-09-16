import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notifier_plugin/notifier_plugin.dart';

/* The examples for this plugin haven't been properly designed yet.
* Sorry for the inconvenience and delay and thank you for your patience.
*/

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {

  TweenNotifier<Color> t = TweenNotifier();

  Widget build(BuildContext context) {

    DateTime a = DateTime.now();
    t.performCircularTween(Tween<Color>(begin: Colors.red, end: Colors.blue), Duration(seconds: 3), reverse: true).then((_)=>print(DateTime.now().difference(a)));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: t - (cc)=>GestureDetector(
          onTapDown: (_)=>t.pause(),
          onTapUp: (_)=>t.play(),
          child: Scaffold(
            backgroundColor: cc ?? Colors.white,
            // body: Center(child: cn - ()=>Text(i.toString())),
          ),
        ),
      ),
    );
  }
}

class TestScaffold1 extends StatefulWidget {
  @override
  _TestScaffold1State createState() => _TestScaffold1State();
}

class _TestScaffold1State extends State<TestScaffold1> {
  HttpNotifier httpNotifier;

  void initState() {
    super.initState();
    httpNotifier =
        HttpNotifier.read(url: "https://www.google.com", initialVal: "", parseResponse: (r){   });
    httpNotifier.addListener(print);
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            CupertinoTextField(
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
                    child: httpNotifier.isLoading
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
                      valTest
                          .performTween(
                              ColorTween(begin: Colors.red, end: Colors.green),
                              Duration(seconds: 1))
                          .then((value) => print("Animation completed!"));
                    },
                  )
                ],
              ),
            ));
  }
}

