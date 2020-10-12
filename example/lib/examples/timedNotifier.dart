import 'package:flutter/services.dart';
import '../storage.dart';

class TimedNotifierExample extends StatefulWidget {

  _TimedNotifierExampleState createState() => _TimedNotifierExampleState();
}

class _TimedNotifierExampleState extends State<TimedNotifierExample> {

  TweenNotifier<double> tn;

  @override
  void initState(){
    super.initState();
    tn = TweenNotifier<double>(initialVal: 0);
    timedNotifier.start();
  }

  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        backgroundColor: Colors.lightBlueAccent[200],
        body: Stack(
          children: [
            timedNotifier - (){
              // The widget tree initially builds twice
              tn.animate(0, 1, timedNotifier.interval - const Duration(milliseconds: 100)).catchError((e)=>null);
              return tn - (d)=> Center(
                child: Container(
                  width:  100.0 + (200.0 * d),
                  height: 100.0 + (200.0 * d),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(radius: 1.0 - d, colors: [Colors.yellow, Colors.lightBlueAccent[200]]),
                  ),
                ),
              );
            },
            const Center(
              child: SizedBox(
                width:  100.0,
                height: 100.0,
                child: DecoratedBox(
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.yellow)
                ),
              ),
            ),
            Positioned(
              bottom: 0.0,
              left: 0.0,
              right: 0.0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12.0),
                child: TextFormField(
                  initialValue: timedNotifier.interval.inMilliseconds.toString(),
                  inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
                  style: TextStyle(color: Colors.grey[900]),
                  decoration: InputDecoration(
                    labelText: "Interval (in milliseconds)",
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    contentPadding: const EdgeInsets.only(left: 12.0),
                    border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  ),
                  onFieldSubmitted: (t) => t.isEmpty?null:timedNotifier.interval = Duration(milliseconds: int.parse(t)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose(){
    super.dispose();
    timedNotifier.stop();
  }

}
