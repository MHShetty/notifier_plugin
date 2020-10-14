import 'package:flutter/services.dart';
import '../storage.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ValNotifierExample extends StatelessWidget {


  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        body: Stack(
          children: [
            bgColorVal - (bgColor) => Positioned.fill(child: ColoredBox(color: bgColor)),
            Center(
              child: ColoredBox(
                color: Colors.white,
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: 16.0),
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: SizedBox(
                              width: 136.0,
                              child: TextFormField(
                                initialValue: vSec.toString(),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.only(left: 12.0, bottom: -8.0),
                                  labelText: "Duration (in seconds)",
                                  border: OutlineInputBorder(),
                                ),
                                inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
                                onChanged: (sec){
                                  if(sec.isEmpty) return;
                                  vSec = int.parse(sec);
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: ~(tc)=> DropdownButton<bool>(
                              value: vMode,
                              hint: Text("reverse"),
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: true, child: Text("forward interpolation")),
                                DropdownMenuItem(value: false, child: Text("reverse interpolation")),
                                DropdownMenuItem(value: null, child: Text("circular interpolation")),
                              ],
                              onChanged: (mode){
                                vMode = mode;
                                bgColorVal(vMode==false?vC.last:vC.first);
                                tc();
                              }
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 100.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 8.0),
                            Text("Colors",style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: ~(cn)=>ListView.builder(
                                scrollDirection: Axis.horizontal,
                                shrinkWrap: true,
                                itemCount: vC.length+1,
                                itemBuilder: (c,i){
                                  Color _ = Colors.blue;
                                  return i==vC.length?
                                  Center(
                                    child: IconButton(
                                      icon: Icon(Icons.add),
                                      onPressed: (){
                                        showDialog(
                                          context: c,
                                          builder: (c) => SimpleDialog(
                                            children: [
                                              ColorPicker(
                                                pickerColor: Colors.blue,
                                                onColorChanged: (c) => _ = c,
                                              ),
                                              RaisedButton(
                                                child: Text("Add color"),
                                                onPressed: (){
                                                  vC.add(_);
                                                  if(tMode==false) bgColorTn(_);
                                                  cn();
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ]
                                          )
                                        );
                                      },
                                    ),
                                  )
                                      :
                                  Center(
                                    child: Dismissible(
                                      key: GlobalKey(),
                                      direction: DismissDirection.vertical,
                                      confirmDismiss: (d) async => vC.length>2,
                                      onDismissed: (d){
                                        vC.removeAt(i);
                                        if(vMode==false) {
                                          if(i==vC.length-1) bgColorVal(vC.last);
                                        }
                                        else if(i==0) bgColorVal(vC.first);
                                      },
                                      child: ~(_)=>InkWell(
                                        onTap: (){
                                          showDialog(
                                              context: c,
                                              builder: (c) => SimpleDialog(
                                                  children: [
                                                    ColorPicker(
                                                      pickerColor: vC[i],
                                                      onColorChanged: (c){
                                                        vC[i] = c;
                                                        if(vMode==false) if(i==vC.length-1) bgColorVal(vC.last);
                                                        else if(i==0) bgColorVal(vC.first);
                                                        _();
                                                      }
                                                    ),
                                                  ]
                                              )
                                          );
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(right: 20.0),
                                          width: 64.0,
                                          height: 64.0,
                                          color: vC[i],
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
                      RaisedButton(
                        child: Text("Animate"),
                        onPressed: () {
                          switch(vMode) {
                            case true: bgColorVal.interpolateR(vC, Duration(seconds: vSec)); break;
                            case false: bgColorVal.interpolateR(vC, Duration(seconds: vSec), reverse: true);break;
                            default: bgColorVal.circularInterpolationR(vC, Duration(seconds: vSec)); break;
                          }
                        },
                      ),
                       SizedBox(
                         height: 8.0,
                       )
                    ],
                  ),
                ),
              ),
            )
          ],
        )
      ),
    );

  }
}
