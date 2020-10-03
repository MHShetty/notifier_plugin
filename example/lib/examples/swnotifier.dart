import '../storage.dart';

class SWNotifierExample extends StatelessWidget {

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mini-Stopwatch"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            swNotifier - (elapsed)=> Text(elapsed.toString(), style: const TextStyle(fontSize: 24.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(icon: const Icon(Icons.fast_rewind), onPressed: (){
                    swNotifier.elapsed = swNotifier.elapsed * 1.5 - swNotifier.elapsed;
                    // Round-off
                    if(swNotifier.elapsed<Duration(seconds: 2)) swNotifier.elapsed = Duration.zero;
                    swNotifier();
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
                    if(swNotifier.elapsed==Duration.zero) swNotifier.elapsed = const Duration(seconds: 2);
                    else swNotifier.elapsed *= 1.5;
                    swNotifier();
                  }, iconSize: 40.0),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

}
