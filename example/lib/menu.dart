import 'package:flutter/material.dart';
import 'package:notifier_plugin/notifier_plugin.dart';

class MenuScreen extends StatelessWidget {

  ValNotifier<Alignment> logoN = ValNotifier(initialVal: Alignment.center);

  Widget build(BuildContext context) {

    return Scaffold(
        body: Center(
          child: Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.yellow,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white, width: 4.0)),
              alignment: Alignment.center,
              child: GestureDetector(
                  onPanUpdate: (d) {
                    logoN(logoN.val + Alignment(d.delta.dx * 2 / 200, d.delta.dy * 2 / 200));
                  },
                  onPanEnd: (d) {
                    logoN.animate(Alignment.center, logoN.val, Duration(milliseconds: 300), curve: Curves.easeIn);
                  },
                  child: logoN - (v) => Align(
                    alignment: v,
                    child: FlutterLogo(size: 50.0),
                  ),
                ),
            ),
    ));
  }
}
