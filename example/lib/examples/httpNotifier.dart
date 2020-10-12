import '../storage.dart';

class HttpNotifierExample extends StatelessWidget {

  Widget build(BuildContext context) {

    print(httpNotifier.headers);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.all_inclusive),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (c) {

                    final Notifier n = Notifier();

                    return n - ()=>SimpleDialog(
                      title: Text("Options"),
                      titlePadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      children: [
                        Row(
                          children: [
                            Text("Request Type:"),
                            Expanded(
                              child: n-()=>DropdownButton<HttpRequestType>(
                                value: httpNotifier.requestType,
                                isExpanded: true,
                                items: HttpRequestType.values.map((e)=>DropdownMenuItem<HttpRequestType>(value: e, child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(e.toString().split('.')[1]),
                                ))).toList(),
                                onChanged: (c){
                                  httpNotifier.requestType = c;
                                  n();
                                }
                              ),
                            ),
                          ],
                        ),
                        const Text("Headers:"),
                        SizedBox(height: 8.0),
                        n - ()=>
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Text("Key",style: TextStyle(fontWeight: FontWeight.bold))]..addAll(
                                  httpNotifier.headers?.map((key, value) => MapEntry(key, TextFormField(
                                    initialValue: key,
                                    decoration: InputDecoration.collapsed(hintText: "Key"),
                                    onChanged: (s){
                                      if(httpNotifier.headers.containsKey(s)){
                                        Scaffold.of(context).showSnackBar(SnackBar(content: Text("The header already consists of a key with the same name!")));
                                        n();
                                        return;
                                      }
                                      httpNotifier.headers.remove(key);
                                      if(s.isNotEmpty&&value.isNotEmpty) httpNotifier.headers[s]=value;
                                      n();
                                    },
                                  )))?.values ?? []
                                )..add(
                                  TextFormField(
                                    decoration: InputDecoration.collapsed(hintText: "New Key"),
                                    onChanged: (s){
                                      httpNotifier.headers ??= {};
                                      if(!httpNotifier.headers.values.contains(null)){
                                        httpNotifier.headers[s]=null;
                                        n();
                                      }
                                    },
                                  )
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Text("Value",style: TextStyle(fontWeight: FontWeight.bold))]..addAll(
                                    httpNotifier.headers?.map((key, value) => MapEntry(key, TextFormField(
                                      initialValue: value,
                                      decoration: InputDecoration.collapsed(hintText: "Value"),
                                      onChanged: (s){
                                        print(key);
                                        httpNotifier.headers[key]=s;
                                        n();
                                      },
                                    )))?.values ?? []
                                )..add(
                                    TextFormField(
                                      decoration: InputDecoration.collapsed(hintText: "New Value"),
                                      onChanged: (s){
                                        httpNotifier.headers ??= {};
                                        if(!httpNotifier.headers.keys.contains(null)){
                                          httpNotifier.headers ??= {};
                                          httpNotifier.headers[null]=s;
                                          n();
                                        }
                                      },
                                    )
                                ),
                              ),
                            )
                          ],
                        ),
                        (HttpRequestType.values.indexOf(httpNotifier.requestType)>4)
                            ?
                            Column(
                              children: [
                                Divider(),
                                TextFormField(
                                  initialValue: httpNotifier.body,
                                  decoration: InputDecoration(
                                    // hintText: "Body",
                                    labelText: "Body",
                                    contentPadding: EdgeInsets.only(bottom: 8, top: 0),
                                  ),
                                  onChanged: (body) => httpNotifier.body = body,
                                  scrollPadding: EdgeInsets.only(top: -16.0),
                                ),
                              ],
                            )
                            : const SizedBox()
                      ],
                    );
                  });
            }),
        title: TextFormField(
          initialValue: httpNotifier.url,
          decoration: InputDecoration.collapsed(
              hintText: "Enter the complete url here",
              hintStyle: TextStyle(color: Colors.white70),
          ),
          style: TextStyle(color: Colors.white),
          keyboardType: TextInputType.url,
          onFieldSubmitted: (url){
            if(url.isEmpty) return;
            try{
              httpNotifier.sync(url: url);
            }catch(e){
              print(e);
              Scaffold.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
        ),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: httpNotifier.sync)
        ],
      ),
      body: httpNotifier - (r) => httpNotifier.isSyncing ? const SmartCircularProgressIndicator() : SingleChildScrollView(child: Text(r.toString())),
    );
  }
}
