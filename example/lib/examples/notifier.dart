import 'package:shared_preferences/shared_preferences.dart';
import '../storage.dart';

TextEditingController tEC;

class NotifierExample extends StatefulWidget {
  @override
  _NotifierExampleState createState() => _NotifierExampleState();
}

class _NotifierExampleState extends State<NotifierExample> {

  @override
  void initState(){
    super.initState();
    tEC = TextEditingController();
  }

  @override
  void dispose(){
    super.dispose();
    tEC.dispose();
    SharedPreferences.getInstance().then((sp) => sp.setStringList("todos", todos));
  }

  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Basic Todo List"),
          centerTitle: true,
          actions: [
            tEC - (c)=>todos.isEmpty?const SizedBox():Builder(
              builder: (c){
                return IconButton(icon: Icon(Icons.clear), onPressed: (){
                  if(todos.isEmpty){
                    Scaffold.of(c).showSnackBar(const SnackBar(content: Text("The todo list is already empty!")));
                    return;
                  }
                  todos.clear();
                  todosN();
                  Scaffold.of(c).showSnackBar(const SnackBar(content: Text("The todo list was cleared!")));
                });
            },
          )],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: TextFormField(
                  controller: tEC,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12.0),
                      suffixIcon: IconButton(
                          icon: tEC - (v) => v.text.isEmpty ? const SizedBox() : Icon(Icons.add),
                          onPressed: (){
                            if(tEC.text=="") return;
                            todos.add(tEC.text);
                            tEC.clear();
                            todosN();
                            tEC.clear();
                          })
                  ),
                  onFieldSubmitted: (s){
                    if(s=="") return;
                    todos.add(s);
                    tEC.clear();
                    todosN();
                  },
                ),
              ),

              todosN - ()=>
                  Expanded(
                    child: ListView.builder(
                      itemCount: todos.length+1,
                      itemBuilder: (c,index)=>
                      index==todos.length?
                      /// Extension method on Val'ue'Notifier<T> enables this (TextEditingController extends ValueNotifier<TextEditingValue>)
                      tEC - (tEV) => tEV.text.isEmpty? todos.isEmpty?Text("You seem to be currently free :)",textAlign: TextAlign.center,style: TextStyle(color: Colors.grey),):const SizedBox() : Todo(todos.length, tEV.text, true)
                          :
                      Todo(index, todos[index], false),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}


class Todo extends StatelessWidget {

  final int index;
  final String todo;
  final bool temp;

  Todo(this.index, this.todo, this.temp);

  Widget build(BuildContext context) {
    return Dismissible(
      key: GlobalKey(),
      confirmDismiss: (d) async=>!temp,
      onDismissed: (d){
        todos.removeAt(index);
        todosN();
        tEC();
      },
      child: GestureDetector(
        onTap: (){
          if(temp){
            todos.add(todo);
            todosN();
            tEC();
          }
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: index%2==0?Colors.blue:Colors.green,
                shape: BoxShape.circle,
              ),
              child: Text((index+1).toString(), style: TextStyle(color: Colors.white)),
            ),
            Text(todo, style: TextStyle(color: temp?Colors.grey:Colors.black)),
          ],
        ),
      ),
    );
  }
}
