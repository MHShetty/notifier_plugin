# notifier_plugin

A Flutter plugin makes state management easier and more efficient than ever!

Please don't use this plugin in production code (until this line is removed).

(The complete documentation will soon be added!)

Overview
---

Imagine if you could `setState`(rebuild) a part of your widget tree without actually designing a new class,
```Dart
  int i = 0;
  
  // [...]
  ~(n)=>RaisedButton(
      child: Text((++i).toString()),
      onPressed: n,
    ) // n is a callable object
  //[...] 
```

Or even better, be able to dynamically pass a value to that part of the tree,
```Dart
  // [...]
  ~(n,v)=>RaisedButton(
      child: Text(v?.toString()??"0"),
      onPressed: ()=>n((v??0)+1),
    ) // Something similar to the counter app
  // [...]
```

Or maybe control that part of the tree from another dimension altogether?

```Dart
  Notifier n = Notifier(); // Globally declared
  
  // Dimension 1
  int i = 0;
  // [...]
    n-()=>Text((++i).toString())
  // [...]
  
  // Dimension 2
  // [...]
    RaisedButton(
      child: Text("Refresh Me"),
      onPressed: n,
    )
  // [...]
```
(Note: The Notifier could be declared within the same class to sync between two widgets of the same tree)

or maybe even pass a value to that dimension.
```Dart
  ValNotifier n = ValNotifier(initialVal: 0);
  
  // Dimension 1
  // [...]
    n-(v)=> Text(v.toString())
  // [...]
  
  // Dimension 2
  // [...]
    RaisedButton(
      child: Text("Increment"),
      onPressed: ()=> n(n.val+1),
    ),
  // [...]
```
(Note: `~(n,v)=>` can be attached to a Widget that can hold both the above widgets to avoid declaring a ValNotifier for the same)

Want to notify multiple values? Try notifying an `Iterable` like `List` or if neccessary a custom object instead!

---

Hmm...that sounds easy and blazing fast to implement. But what about state management? Where will we store all the values that might need to persistently accessed across multiple widgets?

```Dart
// By globally declaring it
String title;
List<String> selectedNames;
int capacity = 10;

// or by declaring it in class with your own common implementations (just what you need!) (More like a central storage system with it's own interfaces)
// that can be as simple as declaring a few variables and then manually notifying the listeners when one or multiple values have been changed,
// or by having your own set of methods that logically update the values and notify the listeners for you (common code/logic)

// I personally prefer to manually notify the listeners only when it's needed, to remain flexible while creating a solution and to then later look for ways to minimize repetitive code. So here's a example of the minified code. (Don't un-necessarily create methods as that would make it difficult to map the logic to the UI)

class Storage extends Notifier
{
  String title;
  List<String> selectedNames;
  int capacity = 10;
  
  bool get isFull  => selectedNames.length==capacity;
  bool get isEmpty => selectedNames.length==0;
  int get nameCount => selectedNames.length;
  
  bool addName(String name){
    if(isFull) return false;
    selectedNames.add(name);
    this(); // call(); // Notify all the listeners
    return true;
  }
}

Storage s = Storage();
```

By declaring them globally or logically as a class (that might or might not extend the Notifier class).

What?

Yes.

But won't that make those values less secure since their global (not private)?

OOP never guarantees security. The concept of **private** variable(s) just exists to make sure that a developer doesn't accidently modify values that (s)he is not supposed to (to ensure normal functioning). Nothing more, nor less. If security is really of that concern, encryption is the way you go. Yes, you can always use SharedPreferences (for non-rooted devices), but encryption at the app's level could add in some security. Maybe you could design a simple class with a getter and setter that could automatically do the encryption or decryption for you. And I don't think the VM should really have a problem with that.

"Don't be trapped by your own dogma."

So how do I access that class/object across multiple dart files?

Creating and importing a common dart file that contains all the required declaration(s) (and default initialization(s)), should do the work.

The beauty of the plugin is purely in it's simplicity. 

If you have been overwhelemed by seeing all the example codes in one go, then just simply use only what you need.

(Read the introduction section to understand how the plugin works from scratch)

Introduction (Pending; Needs formatting)
---

`notifier_plugin` is a plugin that provides different classes and extension methods + operator overloading (for widgets), in order to enable developers to swiftly develop dynamic user-interfaces (in Flutter) with minimal effort. The plugin can then be combined with (custom classes that contain) simple/complex declarations to manage the state of your app in your own way. The plugin was purely made with the intention of doing things in the most simple and efficient way possible, while using minimal or no (extra) resources to implement different concepts. For now, this plugin mainly four types of Notifiers: `Notifier`, `ValNotifier`, `SelfNotifier`, `HttpNotifier`.

Notifier: It's a simple object that can maintain and notify a set of listeners. One could even attach a `Notifier` to it or listen to another `Notifier`. (Note: One cannot attach a Notifier to itself or listen to itself, as that would lead to infinite recursion).

ValNotifier: It is a Notifier that decides to take a step ahead and maintain it's own buffer and actually pass the value to it's listeners (if it can accept one). (Note: A `Notifier` can be called with a value, but it's listeners won't get that value or get null, if they can accept one. This was done to ensure that `ValNotifier` can actually extend `Notifier` while overriding the same set of methods that are used to notify a `Notifier`)

SelfNotifier: It is ValNotifier, that just notifies itself (passes itself to the listeners) when called.

HttpNotifier: It is a special Notifier that maintains a separate buffer for the parameters of a HTTP request so as to avoid boiler-plate code, while performing those requests with same or similar parameters, in different sections of the same app. Since a `HttpNotifier` is a `ValNotifier`, the (extension) methods of ValNotifier can be used with the HttpNotifier. The real benefit of using an (Http)Notifier can come by using it as a `Stream`. (Note: A `Notifier` is not a `Stream`)
