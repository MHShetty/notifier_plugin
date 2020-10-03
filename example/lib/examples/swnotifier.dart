import 'dart:async';

import '../storage.dart';

class SWNotifierExample extends StatefulWidget {

  @override
  _SWNotifierExampleState createState() => _SWNotifierExampleState();
}

class _SWNotifierExampleState extends State<SWNotifierExample> {

  final ScrollController s = ScrollController();

  double fT = 1.0;
  double bT = 1.0;

  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Mini-Stopwatch")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height/2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  swNotifier - (elapsed)=> Text(elapsed.toString(), style: const TextStyle(fontSize: 24.0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(icon: const Icon(Icons.fast_rewind), onPressed: (){
                          double _bT = bT;
                          swNotifier.elapsed -= const Duration(seconds: 2) * (bT+=0.25);
                          if(swNotifier.elapsed<Duration(seconds: 2)) swNotifier.elapsed = Duration.zero;
                          swNotifier();
                          Future.delayed(Duration(milliseconds: 700),(){
                            if((bT-_bT)==0.25) bT = 1.0;
                          });
                        }, iconSize: 40.0),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ~(n)=>IconButton(icon: Icon(swNotifier.isPlaying?Icons.pause:Icons.play_arrow), onPressed: (){
                          swNotifier.isPlaying?swNotifier.pause():swNotifier.play();
                          n();
                        }, iconSize: 40.0),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(icon: const Icon(Icons.fast_forward), onPressed: (){
                          double _fT = fT;
                          if(swNotifier.elapsed==Duration.zero) swNotifier.elapsed = const Duration(seconds: 2);
                          else swNotifier.elapsed += const Duration(seconds: 2) * (fT+=0.25);
                          print(fT);
                          Future.delayed(Duration(milliseconds: 700),(){
                            if((fT-_fT)==0.25) fT = 1.0;
                          });
                          swNotifier();
                        }, iconSize: 40.0),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.maxFinite,
                    child: FlatButton(child:
                      const Text("Lap", style: const TextStyle(fontSize: 18.0)),
                      onPressed: (){
                        lap();
                        s.jumpTo(0.0);
                      }),
                  ),
                ],
              ),
            ),
            Expanded(
              child: lapsN - (laps)=>ListView.builder(
                itemCount: laps.length,
                controller: s,
                itemBuilder: (c,i){
                  i = laps.length-(i+1);
                  return Dismissible(
                    key: GlobalKey(),
                    onDismissed: (d){
                      laps.removeAt(i);
                    },
                    child: ListTile(
                      title: Text(
                        laps[i].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    )
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
