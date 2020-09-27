import 'storage.dart';

class MenuScreen extends StatelessWidget {

  final ValNotifier<Alignment> logoN = ValNotifier(initialVal: Alignment.center);

  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: TextFormField(
              initialValue: mainTitle.val,
              textAlign: TextAlign.center,
              decoration: InputDecoration.collapsed(hintText: "Main title", hintStyle: TextStyle(color: Colors.white70)),
              style: TextStyle(color: Colors.white, fontSize: 20),
              onChanged: mainTitle,
            ),
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white, width: 4.0)
                  ),
                    child: GestureDetector(
                        onPanUpdate: (d) => logoN(logoN.val + Alignment(d.delta.dx / 60, d.delta.dy / 60)),
                        onPanEnd: (d) =>
                            logoN.animate(Alignment.center, logoN.val, Duration(milliseconds: 300), curve: Curves.easeInSine),
                        child: logoN - (v) => Align(
                          alignment: v,
                          child: FlutterLogo(size: 75.0),
                        ),
                      ),
                  ),
                const SizedBox(height: 12.0),
                mainTitle - (title) => Text(title.isEmpty?"Please enter some title on the AppBar's TextField!":"Welcome to ${title.toLowerCase()}!"),
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0)
                  ),
                  child: ListView(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 4.0),
                        onTap: ()=>Navigator.of(context).pushNamed("notifier"),
                        title: Text("1. Notifier"),
                        subtitle: sp - (s)=>  Text("A simple example that uses a Notifier and certain helper methods and classes to create a basic dynamic todo list. ${todos.isEmpty?"":"There are ${todos.length} todos in the list."}"),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 4.0),
                        onTap: ()=>Navigator.of(context).pushNamed("valNotifier"),
                        title: Text("2. ValNotifier"),
                        subtitle: Text("A simple screen that is capable of transitioning from one background color to another with the help of a ValNotifier. (uncontrolled)"),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 4.0),
                        onTap: ()=>Navigator.of(context).pushNamed("tweenNotifier"),
                        title: Text("3. TweenNotifier"),
                        subtitle: Text("A simple screen that is capable of transitioning from one background color to another with the help of a TweenNotifier. (controlled)"),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 4.0),
                        onTap: ()=>Navigator.of(context).pushNamed("httpNotifier"),
                        title: Text("4. HttpNotifier"),
                        subtitle: Text("A simple example that uses a HttpNotifier. A mini-custom http request-er that prints the retrieved response. (Current URL: ${httpNotifier.url})"),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 4.0),
                        onTap: ()=>Navigator.of(context).pushNamed("timedNotifier"),
                        title: Text("5. TimedNotifier"),
                        subtitle: Text("A simple example that implements a glowing sun with the help of a TimedNotifier. (Current Interval: ${timedNotifier.interval.inMilliseconds} ms)"),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 4.0),
                        onTap: ()=>Navigator.of(context).pushNamed("swNotifier"),
                        title: Text("6. SWNotifier"),
                        subtitle: Text("A simple example that implements a stopwatch with the help of a SWNotifier. (Last elapsed: ${swNotifier.elapsed})"),
                      ),
                    ],
                  ),
                )
              ],
            ),
      )),
    );
  }
}
