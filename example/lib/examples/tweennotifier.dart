import 'dart:io';

import 'package:flutter/services.dart';
import '../storage.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class TweenNotifierExample extends StatelessWidget {
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            bgColorTn -
                (bgColor) => Positioned.fill(child: ColoredBox(color: bgColor)),
            Positioned(
              left: 20,
              top: 40,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                ),
              ),
            ),
            Center(
              child: ColoredBox(
                color: Colors.white,
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: SizedBox(
                              width: 136.0,
                              child: TextFormField(
                                initialValue: tSec.toString(),
                                keyboardType: Platform.isIOS
                                    ? TextInputType.numberWithOptions(
                                        signed: true)
                                    : TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding:
                                      EdgeInsets.only(left: 12.0, bottom: -8.0),
                                  labelText: "Duration (in seconds)",
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (sec) {
                                  if (sec.isEmpty) return;
                                  tSec = int.parse(sec);
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: ~(tc) => DropdownButton<bool>(
                                value: tMode,
                                hint: Text("reverse"),
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                      value: true,
                                      child: Text("forward interpolation")),
                                  DropdownMenuItem(
                                      value: false,
                                      child: Text("reverse interpolation")),
                                  DropdownMenuItem(
                                      value: null,
                                      child: Text("circular interpolation")),
                                ],
                                onChanged: (mode) {
                                  tMode = mode;
                                  bgColorTn(
                                      tMode == false ? tC.last : tC.first);
                                  tc();
                                }),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 100.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 8.0),
                            Text("Colors",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: ~(cn) => ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    shrinkWrap: true,
                                    itemCount: tC.length + 1,
                                    itemBuilder: (c, i) {
                                      Color _ = tC.first;
                                      return i == tC.length
                                          ? Center(
                                              child: IconButton(
                                                icon: Icon(Icons.add),
                                                onPressed: () {
                                                  showDialog(
                                                    context: c,
                                                    builder: (c) =>
                                                        SimpleDialog(
                                                      children: [
                                                        ColorPicker(
                                                          pickerColor: tC.first,
                                                          onColorChanged: (c) =>
                                                              _ = c,
                                                        ),
                                                        RaisedButton(
                                                          child:
                                                              Text("Add color"),
                                                          onPressed: () {
                                                            tC.add(_);
                                                            if (tMode == false)
                                                              bgColorTn(_);
                                                            cn();
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                        )
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          : Center(
                                              child: Dismissible(
                                                key: GlobalKey(),
                                                direction:
                                                    DismissDirection.vertical,
                                                confirmDismiss: (d) async =>
                                                    tC.length > 2,
                                                onDismissed: (d) {
                                                  tC.removeAt(i);
                                                  if (tMode == false) {
                                                    if (i == tC.length - 1)
                                                      bgColorTn(tC.last);
                                                  } else if (i == 0)
                                                    bgColorTn(tC.first);
                                                },
                                                child: ~(_) => InkWell(
                                                      onTap: () {
                                                        showDialog(
                                                            context: c,
                                                            builder: (c) =>
                                                                SimpleDialog(
                                                                    children: [
                                                                      ColorPicker(
                                                                          pickerColor: tC[
                                                                              i],
                                                                          onColorChanged:
                                                                              (c) {
                                                                            tC[i] =
                                                                                c;
                                                                            if (tMode == false) if (i ==
                                                                                tC.length - 1)
                                                                              bgColorTn(tC.last);
                                                                            else if (i ==
                                                                                0)
                                                                              bgColorTn(tC.first);
                                                                            _();
                                                                          }),
                                                                    ]));
                                                      },
                                                      child: Container(
                                                        margin: EdgeInsets.only(
                                                            right: 20.0),
                                                        width: 64.0,
                                                        height: 64.0,
                                                        color: tC[i],
                                                      ),
                                                    ),
                                              ),
                                            );
                                    },
                                  ),
                            )
                          ],
                        ),
                      ),
                      ~(p) => RaisedButton.icon(
                            icon: Icon(bgColorTn.isPaused == false
                                ? Icons.pause
                                : Icons.play_arrow),
                            label: Text(
                                bgColorTn.isPaused == false ? "Pause" : "Play"),
                            onPressed: () {
                              if (bgColorTn.isPerformingTween) {
                                if (bgColorTn.isPaused)
                                  bgColorTn.play();
                                else
                                  bgColorTn.pause();
                              } else {
                                Future f;
                                switch (tMode) {
                                  case true:
                                    f = bgColorTn.interpolateR(
                                        tC, Duration(seconds: tSec));
                                    break;
                                  case false:
                                    f = bgColorTn.interpolateR(
                                        tC, Duration(seconds: tSec),
                                        reverse: true);
                                    break;
                                  default:
                                    f = bgColorTn.circularInterpolationR(
                                        tC, Duration(seconds: tSec));
                                    break;
                                }
                                f.then((_) => p());
                              }
                              p();
                            },
                          ),
                      const SizedBox(height: 8.0)
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/*
                          RaisedButton.icon(
                            icon: Icon(Icons.p),
                            onPressed: (){
                              switch(tMode){
                                case true: bgColorTn.interpolateR(tC, Duration(seconds: tSec)); break;
                                case false: bgColorTn.interpolateR(tC, Duration(seconds: tSec), reverse: true);break;
                                default: bgColorTn.circularInterpolationR(tC, Duration(seconds: tSec)); break;
                              }
                            },
                          ),
                          RaisedButton(
                            child: Text("Animate"),
                            onPressed: (){
                              switch(tMode){
                                case true: bgColorTn.interpolateR(tC, Duration(seconds: tSec)); break;
                                case false: bgColorTn.interpolateR(tC, Duration(seconds: tSec), reverse: true);break;
                                default: bgColorTn.circularInterpolationR(tC, Duration(seconds: tSec)); break;
                              }
                            },
                          ),
                          RaisedButton(
                            child: Text("Animate"),
                            onPressed: (){
                              switch(tMode){
                                case true: bgColorTn.interpolateR(tC, Duration(seconds: tSec)); break;
                                case false: bgColorTn.interpolateR(tC, Duration(seconds: tSec), reverse: true);break;
                                default: bgColorTn.circularInterpolationR(tC, Duration(seconds: tSec)); break;
                              }
                            },
                          ),
* */
