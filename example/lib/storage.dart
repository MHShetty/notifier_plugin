import 'package:notifier_plugin/notifier_plugin.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart';

// import 'package:flutter/services.dart';
export 'package:flutter/material.dart';
export 'package:notifier_plugin/notifier_plugin.dart';

void loadRes() async {
  todos = (await sp.future).getStringList("todos") ?? [];
  // SystemChannels.lifecycle.setMessageHandler((m) async {
  //   print("System Channel $m");
  //   // SharedPreferences.getInstance().then((sp) => sp.setStringList("todos", todos));
  //   return "";
  // });
}

ValNotifier<String> mainTitle = ValNotifier(initialVal: "An example app");

/// Notifier screen
WFuture<SharedPreferences> sp = WFuture(SharedPreferences.getInstance());
Notifier todosN = Notifier();
List<String> todos;

/// ValNotifier screen
ValNotifier<Color> bgColorVal = ValNotifier(initialVal: Colors.blue);
List<Color> vC = [Colors.blue, Colors.green];
bool vMode = true;
int vSec = 1;

/// TweenNotifier screen
TweenNotifier<Color> bgColorTn = TweenNotifier(initialVal: Colors.green);
List<Color> tC = [Colors.green, Colors.blue];
bool tMode = true;
int tSec = 1;

/// HttpNotifier screen
HttpNotifier httpNotifier = HttpNotifier(url: "https://www.flutter.dev", parseResponse: (r){
  if(r is Response) return r.body;
  return r;
});

/// TimedNotifier screen
TimedNotifier timedNotifier = TimedNotifier(interval: Duration(seconds: 1), startOnInit: false);

/// SWNotifier screen
SWNotifier swNotifier = SWNotifier(startOnInit: true, pauseOnInit: true);
ValNotifier<List<Duration>> lapsN = ValNotifier(initialVal: []);
void lap(){
  lapsN.val.add(swNotifier.lap());
  lapsN();
}