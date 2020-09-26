import '../storage.dart';

class SWNotifierExample extends StatefulWidget {
  @override
  _SWNotifierState createState() => _SWNotifierState();
}

class _SWNotifierState extends State<SWNotifierExample> {

  initState(){
    super.initState();
    swNotifier.start();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: swNotifier - ()=> Text(swNotifier.elapsed.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0)),
      ),
    );
  }
}

