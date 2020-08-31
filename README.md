# notifier_plugin

A Flutter plugin makes state management and building dynamic user interfaces easier and more efficient than it could ever be!

Please don't use this plugin in production code (until this line is removed).

(The complete documentation will soon be added!)

## Random examples (temporary)

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

## Introduction and Overview

`notifier_plugin` is a plugin that provides different classes and extension methods while overloading certain operators for widgets, in order to enable developers to swiftly develop dynamic user-interfaces (in Flutter) with minimal effort. The plugin can then be combined with (custom classes that contain) simple/complex declarations to manage the state of your app in your way. The plugin was purely made with the intention of doing things in the most simple and efficient way possible, while using minimal or no (extra) resources to implement different concepts.

For now, this plugin mainly four types of Notifiers: `Notifier`, `ValNotifier`, `SelfNotifier`, `HttpNotifier`.

[Notifier](#notifier): A simple object that can maintain and notify a set of listeners. It supports attaching one/multiple Notifier and listening to other Notifiers. One could even poll it for certain number of times or over a fixed duration.

[ValNotifier](#valnotifier): A `Notifier` that can notify its listeners with the value it was called with and maintains a buffer for the same. One could directly perform a Tween through the Notifier through the `performTween()` method. It supports all the methods and getters and setters of a Notifier.

[HttpNotifier](#httpnotifier): A `ValNotifier` that maintains a separate buffer for the parameters of a HTTP request so as to avoid boiler-plate code, while performing those requests with same or similar parameters in different sections of the same app. Since a `HttpNotifier` is a `ValNotifier`, the  methods of `ValNotifier` can still be used, while using a `HttpNotifier`. The real benefit of using an (Http)Notifier can come by using it as a `Stream`. (Note: A `Notifier` is not a `Stream`)

[TimedNotifier](#timednotifer): A `Notifier` that can be polled in a very controlled manner.

[TweenNotifier](#tweennotifier): A `ValNotifier` that can perform a Tween in a very controlled manner.

These `Notifier`(s) and the extension methods used on certain pre-defined types overload certain operator methods in a specific way to help developers quickly implement dynamic UI in Flutter in a scalable manner with minimal effort/code. (Read more about it in [this section](#the-magic-of-extension-methods-and-operator-overloading).)

Not sure with how you can use this plugin for state management? [This section](#state-management-with) might be a small help you. 

Also, it might be worth reading the [special case of Notifier extends Iterable\<Notifier>](#the-special-case-of-notifier-extends-iterablenotifier) used in this plugin.

## Concepts used while designing the Notifier classes

### Instantiating a Notifier

> Notifier({Iterable\<Notifier> attachNotifiers, Iterable\<Notifier> listenToNotifiers, Iterable\<Notifier> mergeNotifiers, Iterable\<Function> initialListeners, bool removeListenerOnError(Error)})

**attachNotifiers**: Attach these Notifier(s) to the Notifier that's being instantiated.

**listenToNotifiers**: Make the Notifier that is being instantiated listen to these Notifier(s).

**mergeNotifiers**: Merge the listeners of these Notifier(s) while instantiating this Notifier.

**initialListeners**: Pass a set of listeners to be merged to the default set of listeners.

**removeListenerOnError**: A special parameter that accepts a function that can be used to handle anything that gets thrown while notifying the listeners/even remove them (if needed) (if this function returns `true` the listener gets removed; if it returns `false` then nothing really happens; and if it returns `null`, the error simply gets `rethrown`)

> ValNotifier\<T>({T initialVal, Iterable\<Notifier> attachNotifiers, Iterable\<Notifier> listenToNotifiers, Iterable\<Notifier> mergeNotifiers, Iterable\<Function> initialListeners, bool removeListenerOnError(Error)})

**initialVal**: The value with which the ValNotifier should be instantiated. (ValNotifier-specific)

> HttpNotifier({@required String url, HttpRequestType requestType, Map<String, String> headers, String body, Encoding encoding, dynamic initialVal, bool syncOnCreate=true, Function(dynamic) parseResponse, Iterable\<Notifier> attachNotifiers, Iterable\<Notifier> listenToNotifiers, Iterable\<Notifier> mergeNotifiers, Iterable\<Function> initialListeners, bool Function(Error) removeListenerOnError})

**url**: The url to which the HttpRequest needs to be performed. (needs to be a valid url/perhaps satisfy the regex used internally)

**requestType**: The requestType determines the type of http request to be perfomed while the `sync()` method is called. (cannot be set to null)

**headers**: The headers to be passed while performing an Http Request, through the HttpNotifier.

**body**: The body to be passed while performing an Http Request that supports passing a body. (Trying to set/get body for an HttpRequestType that does not support holding a body leads to the failure of one of the assert statement)

**encoding**: The encoding of the body to be passed. The rules for setting/getting a body applies to this parameter (encoding)

**syncOnCreate**: A bool value that decides whether the `sync` method should be through the constructor.

**parseResponse**:  A function that can be used to parse the response value, before it gets passed to all the listeners.

Almost the above parameters (for HttpNotifier) can be retrieved/modified at a later stage, unless specified. (body and encoding are dependent on the type of HttpRequestType set)
These values are then persistently stored within the HttpNotifier, so if we try to sync,

#### Copy Constructor (By cloning):

> Notifier.from(Notifier)
>
> ValNotifier.from(ValNotifier)

It accepts an Notifier and just clones it into a new Notifier that would then need to be separately maintained. A disposed Notifier cannot be cloned.

There are numerous other ways to instantiate a Notifier. For example, one could use the instance/static method `merge`, to merge one/multiple notifiers into one, or use an or some extension method's overloaded operator to do the same.

### Adding listeners to a Notifier

Adding a listener to a notifier is just as good as just adding a function to a list that can only hold functions. The two accepted types of `Function`s is a function that accepts nothing or function that accepts a single parameter. (Note: For the default type of Notifier, a listener that accepts a parameter always recieves a null and a ValNotifier can accept a listener that does not accept a parameter)

This can be done with the help of two methods, namely,

  **a. addListener**  (Accepts a Listener/Function; returns the hashCode of that listener if it gets successfully added, else null)
  
  **b. addListeners** (Accepts an Iterable<Listener/Function>; returns an Iterable<int> of hashCodes. The success of adding of each method can be determined by the value at it's corresponding index in the Iterable)
  
  **c. customListener(s)Adder**: Separately map one/multiple listeners to multiple different notifiers in one method call.

An example for Notifier,

```Dart
Notifier n0 = Notifier(); // Instantiating a Notifier
Notifier n1 = Notifier(); // Instantiating a Notifier

n0.addListener(()=>print("Notified!")); // Adding a single listener to the Notifier
n0.addListener((v)=>print("null==$v")); // Adding a single listener to the Notifier (that accepts a parameter) (the parameter will always return null for a
n0.addListeners([()=>print(0),(v)=>print("This is $v.")]); // Adding multiple listeners to the same Notifier with the help of an Iterable

[n0,n1].addListener(print);
[n0,n1].addListeners(()=>print("This should be"),()=>print("easy"));

Notifier.customListenerAdder({n0: ()=>print(0), n1: ()=>print(1)});
Notifier.customListenersAdder({n0: [()=>print("Zero"),()=>print("0 == 0")], n1: [()=>print(":)"),()=>print(";)")]});
```

Note: All the above methods have an static implementation.

An example for ValNotifier,

```Dart
ValNotifier vn = ValNotifier();
vn.addListener(()=>print("Notified! Yeah it's fine if I was never made to receive a value :)"));
vn.addListener(print);

/// All the methods used in Notifier can be used for a ValNotifier
```

Note: All the above methods have an static implementation.

**Exception cases**

```Dart
n.addListener(n); // You cannot make a Notifier listen itself (it compiles)
n.addListener(null); // Simply returns null
n.addListener((p1,p2)=>print("$p1$p2")); // this listener won't get added, since only no/one parameter type of Listener is supported by any Notifier
n.addListener(existingListener); // works for now ... but is very likely to turn into an Exception in the near future
n.addListener((p)=>print(p)); // For a normal Notifier, only a null would be passed (irrespective of the value passed while calling)

// However for a ValNotifier, things work as expected.
```

### Calling a Notifier

Whenever you want to notify all the listeners of a Notifier, just call it. `MyNotifier()` Yeah, that's it.

```Dart
Notifier n = Notifier();
n.addListener(()=>print("Notified!"));
n();
n(1); // Listeners won't get it, since this is not a ValNotifier
n();

// Prints "Notified!" thrice
```

So what does a Notifier return? Just itself.

Hmm...what does that mean?

It means that the above code can be re-written as...

```Dart
Notifier n = Notifier();
n.addListener(()=>print("Notified!"));
n()(1)();
```

But what if my listeners were made to perform a long list of operations and I just can't afford to wait until every listeners get notified?

```Dart
n.asyncNotify(); // returns Future<Notifier>
```

The `asyncNotify` method was made just for you!

Other ways of notifying/calling the listener...(they too just return a `Notifier`)

```Dart
~n;
n.notify(1);
n.notifyListeners();
n.sendNotification();
```

And what about ValNotifier? Can it be called without an value like a Notifier? What value gets passed to the listeners in that case?

Yes, it can be called without a passing a value. The last notified value gets passed in that case. (That's what the buffer was made for!)

```Dart
ValNotifier vn = ValNotifier(initialVal: "Hello World!");

vn.addListener(()=>print("Notified! Yeah it's fine if I was never made to receive a value :)"));
vn.addListener(print); // That was easy!

vn();  // Notifies all the listeners with "Hello World!" string (those who can accept it)
vn(5); // Notifies all the listeners with the integer value 5 (those who can accept it)
vn();  // Notifies all the listeners with the integer value 5 (those who can accept it)
```

### Polling a Notifier

A Notifier supports polling itself (at least in this plugin). You could either poll a Notifier for a fixed number of times or poll it for over a certain Duration.

```Dart
n.poll(100); // Calls the notifier for 100 times and returns the total Duration taken to notify the listeners for those many times as an Future
n.pollFor(Duration(seconds: 10)); // Repeatedly notifies the listeners until the passed duration hasn't elapsed. Returns a Future<Notifier>
```

### Attaching Notifiers

A Notifier can attach another Notifier to itself i.e. the attached notifier will get called whenever the main Notifier gets called. However, a notifier cannot attach itself to itself (as this would lead to an infinite loop of notifications) nor can it attach another Notifier that has attached the current notifier (for the same reason).

```Dart
Notifier n1 = Notifier();
Notifier n2 = Notifier();

n1.addListener(()=>print("N1"));
n2.addListener(()=>print("N2"));

n1(); // Prints "N1"
n2(); // Prints "N2"

n1.attach(n2); // works

n1(); // Prints "N1" and then "N2"
n2(); // Prints "N2"

// n2.attach(n1); // throws an exception

n1.detach(n2);
n2.attach(n1);

n1(); // Prints "N1"
n2(); // Prints "N2" and then "N1"
```

You can attach/detach multiple listeners in one go.

```Dart
Notifier n3 = Notifier();
n1.attachAll([n2,n3]);
n1.detachAll([n3,n2]);
```

For attach, the method will only return false if the passed parameter is null.

Whereas for detach, it'll return false if the passed Notifier is not attached to the concerned Notifier.

If anything unexpected happens, an exception shall be thrown.

### Listening to Notifiers

A Notifier can easily listen to one/multiple notifiers by using the `startListeningTo`/`startListeningtoAll` method or stop listening to them using the `stopListeningTo`/`stopListeningToAll` method. However a Notifier cannot listen to a Notifier that is already listening to it or to a Notifier that is attached to it.

```Dart
Iterable<Notifier> n = List.generate(3,(i)=>Notifier()); // Instantiates 3 Notifiers n[0] n[1] n[2]

n[0].startListeningTo(n[1]);
n[0].stopListeningTo(n[1]);

n[1].startListeningTo(n[2]);
n[1].stopListeningToAll(n); // Will return false for itself

// n[2].startListeningTo(n[2]); // assert error (A Notifier cannot listen to itself (for the same infinite recursion reason)) 
// n[2].startListeningTo(n);    // assert error (since n[2] is present in this list (infinite recursion))

/// Magic of extension methods

n.startListeningTo(n3); // makes all the notifiers in iterable n, listen to n3
n.stopListeningTo(n3);  // makes all the notifiers in iterable n, listen to n3

n.startListeningToAll([n3,n4]); // makes all the notifiers in n listen to n3 and n4
n.startListeningToAll([n4,n3]); // makes all the notifiers in iterable n, stop listening to n4 and n3
```

When a Notifier listens to a ValNotifier, it does get called by the ValNotifier (but the value however is not passed to it's listeners) whereas when a ValNotifier listens to a Notifier, it just simply calls it like any other listener and hence the expected behavior will occur.

However, when a ValNotifier<T> listens to another ValNotifier<T> it gets the value that's been notified. And just by any chance that attaching a listener is similar to a Notifier listening to it, then....you are right :blush: In fact, it's the same thing, since all that a Notifier maintains is a list of listeners.
  
So how do I connect 2 listeners in such a way that I can notify them in one go and maybe even connect or disconnect them in one go?

Well, that's what one of the reasons why all the methods of a Notifier were re-implemented as extension methods on Iterable<Notifier>,
  
```Dart
Notifier n1 = Notifier();
Notifier n2 = Notifier();

// Create a connection
Iterable<Notifier> n = [n1,n2];

n();
n.addListener(print);
n.removeListener(print);

// Dispose the connection
n = null;

// Create, use and dispose the connection in one go (just as http.Client is unknowingly used nowadays)
[n1,n2]();

// Even doing this is not a bad idea (if you just want to notify both once)
n1(); n2();

// If you want to connect two Iterable<Notifier>s together then just add them to a single Iterable<Notifier>
// Iterable<Notifier> n = []..addAll(firstIterable)..addAll(secondIterable);
```

### Notifying a specific listener (implemented as callByHashCode(s) for now)

One can easily notify a specific listener of the notifier if it's `hashCode` is known.

```Dart
Notifier n = Notifier();
int hashCode = n.addListener(()=>print("It's never too late to smile..."));
n.addListener(()=>print("Weird flex, but ok!"));

n(); // notifies both the the listeners

n.notifyByHashCode(hashCode); // Only notifies the listener whose hashCode is passed
```

or maybe multiple of such listeners

```Dart
Notifier n = Notifier();

int h0 = n.addListener(()=>print(1));
n.addListeners(()=>print(1),()=>print(2));
int h1 = n.addListener(()=>print(2));

n(); // 1 1 2 1

n.notifyByHashCodes([h1,h0]); // 2 1
```

### Removing listeners from a Notifier

Listeners can be removed from a Notifier in two ways: 

#### a. By reference(s)
 
You could just simply use the `removeListener()` method while passing the listener itself to remove it from an undisposed Notifier. (Removing multiple listeners by reference is supported)
 
 ```Dart
Notifier n = Notifier();
Function r = ()=>print("Notified");
 
/// Removing a single function by reference
 
n.addListener(r);    // Adding a listener (returns the hash_code_of_function_stored_in_r)
n.removeListener(r); // Removing the same listener (returns true)
 
n.addListener(()=>print("Notified"));    // Adding a listener (returns the hash_code_of_the_passed_anonymous_function)
n.removeListener(()=>print("Notified")); // Trying to remove the same listener (returns false; since the method does not exist according to Dart, since there is no real way to compare two functions in Dart(Flutter), by their definition..at least for now)
 
n.addListener(print);    // Adding a listener 
n.removeListener(print); // Removing the same listener (returns true; since the reference is same and known)

/// Removing multiple listeners by reference
 
n.addListeners([print,r]);    // Adding multiple listeners   (returns (hash_code_of_print_function, hash_code_of_function_stored_in_r))
n.removeListeners([print,r]); // Removing multiple listeners (returns (true, true))

n.addListeners([print,null]);    // Adding multiple listeners   (returns (hash_code_of_print_function, null))
n.removeListeners([null,print]); // Removing multiple listeners (returns (false, true))
```
 
 #### b. By hashcode(s)
 
 A listener of a Notifier can be removed, even if only it's hashCode is known. (Removing multiple listeners by hashCodes is supported)
 
 ```Dart
 Notifier n = Notifier();
 
 /// Removing a single listener
 int hashCode = n.addListener(()=>print("Hmm...something's brewing.."));
 n.removeListenerByHashCode(hashCode); // removes the anonymous listener from the code
 
 /// Removing multiple listeners
 Iterable<int> hashCodes = n.addListeners([()=>print(123),()=>print(456)])
 n.removeListenersByHashCodes(hashCodes); // removes 
 ```
 
### Clearing all the listeners of a Notifier

You could simply clear the listeners of a Notifier by using the `clearListeners()` method. It simply just clears the List of listeners maintained by the Notifier. 

**Important Note**: Clearing the listeners of a Notifier would also clear the notifier(s) attached to it and also stop notifying the Notifier(s) listening to it.

An example to explain this phenomenon,

```Dart
Notifier n1 = Notifier();
Notifier n2 = Notifier();

n1.addListener(()=>print("N1!"));
n1(); // Prints "N1!"

n2.addListener(()=>print("N2!"));
n2(); // Prints "N2!"

n2.attach(n1);
n2(); // Prints "N2!" and then "N1!"

n2.clearListeners();
n2(); // Doesn't really do anything

n1.startListeningTo(n2);
n2(); // Prints "N1!" (since n1 is listening to n2)

n2.clearListeners();
n2(); // Still prints "N1!"

n1.clearListeners();
n2(); // Doesn't really do anything
```

### Initializing a Notifier

Generally, a disposed object cannot be used again. However, that's not the case with a Notifier. You can re-init a Notifier once it's disposed, and that's what that `init` method was made for. However, it's highly recommended that you don't dispose it until you are completely done with and use the instance method `clearListeners()` to clear all the listeners in one go. The `init()` method was just created with the intention of being able to bring the Notifier for whatever reasons.

```Dart
Notifier n = Notifier(); // auto-init()

n.dispose(); // Disposing the Notifier n

// Trying to call almost any method or getter, would throw an StateError here.

n.init(/*[...]*/); // init()
```

### Disposing a Notifier

Disposing a Notifier generally just sets all it's members to null and does not have any special case of resource de-allocation. Once the notifier is disposed, trying to call almost any method or getter on it would throw an (State)Error. A disposed Notifier can be re-init with the help of the init() method.

```Dart
Notifier n = Notifier();

// Use the notifier for a while

n.dispose(); // Disposing the Notifier n

n.clearListeners(); // throws a StateError
```

### Tweening a ValNotifier (Not fully implemented)

> Future<ValNotifier<T>> performTween(Tween<T> tween, Duration duration, {Curve curve = Curves.linear})

Tweening a ValNotifier? You mean those animation stuff? Yes.

```Dart
ValNotifier v = ValNotifier();

valTest.performTween(IntTween(begin: Colors.red, end: Colors.green), Duration(seconds: 1)).then((value) => print("Animation completed!"));
```

You can easily animate through a Tween of values as long as you have a Tween or can implement a class that extends and properly implements one.

### Extension methods and operator overloading

Extension methods and operator overloading

```Dart
~(n,v) => GestureDetector(
  onHorizontalDragUpdate: (d) => n(d.localPosition.dx),
  child: Container(
    height: 200,
    width: 200,
    decoration: BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: Colors.white, width: 4.0)
    ),
    alignment: Alignment.center,
    child: Text(v.toString(), style: TextStyle(color: Colors.white)),
  ),
)
```

## Notifier

Instance method | Description
--------------- | -----------
addListener(Function listener) → int | Adds a listener to the Notifier and returns the listener's `hashCode` if successfully added else returns `null` (adding a listener that already exists)
addListeners(Iterable<Function> listeners) → Iterable\<int> | Adds multiple listeners to a Notifier and returns an Iterable<int> of hashCodes. If the corresponding index has an hashCode, then the listener at that index was added successfully added else null.
call([dynamic _]) → Notifier | Calls a Notifier to notify it's listeners. (notifierInstance() invokes this method) 
asyncNotify([dynamic _]) → Future\<Notifier> | Asynchronously notify the listeners without blocking the caller's execution thread.
attach(Notifier notifier) → bool | Attaches the passed notifier to the current `Notifier`. The current `Notifier` will call the attached notifier whenever it gets called. 
attachAll(Iterable\<Notifier> notifiers) → Iterable\<bool> | Attaches the passed notifier(s) to the current Notifier. The current Notifier calls all the attached notifiers (as long as they are attached to it) whenever it gets called. Calling `clearListeners()` clears the attached Notifiers too. Read the concepts section for more info.
detach(Notifier notifier) → bool | Detaches a notifier attached to it. If the Notifier isn't attached then the method simply returns false, else true.
detachAll(Iterable\<Notifier> notifiers) → Iterable\<bool> | Tries to detach all the notifiers given to it. Sets true at the corresponding index, if the Notifier was previously attached else false.
startListeningTo(Notifier notifier) → bool | Starts listening to the passed Notifier (if it isn't currently doing so). Returns false if it was already somehow listening to it else true.
startListeningToAll(Iterable<Notifier> notifiers) → Iterable\<bool> | Starts listening to all the passed notifiers and for any given index in the Iterable<bool> being returned, it sets false if the Notifier was already being listened to, else true.
stopListeningTo(Notifier notifier) → bool | Stops listening to the passed Notifier. Returns false if it was never listening to one else true.
**stopListeningToAll(Iterable<Notifier> notifiers) → Iterable\<bool> | Stops listening to all the notifiers in the passed Iterable\<Notifier>. For any given index, it sets true if the Notifier was previously listening to that Notifier else sets false.
isListeningTo(Notifier notifier) → bool | Checks if the current Notifier isListening to the passed Notifier. If it is the returns true, else false.
**isListeningToAll(Iterable<Notifier> notifiers) → Iterable\<bool> ** | **234**
**notifyByHashCode(int hashCode) → bool | Just notifies a listener by hashCode (if it exists as a part of it). The hashCode can be obtained from the return value of addListener. Calls the listener and returns true if the listener is found else false.
**notifyByHashCodes(Iterable\<int> hashCodes) → Iterable\<bool> | Notifies multiple listeners based on the given hashCodes. If the listener is found it sets true at the corresponding index of that listener else false.
**hasAttached(Notifier notifier) → bool | Checks if the current Notifier is attached to another Notifier. Returns true if it is else false.
**hasAttachedAll(Iterable\<Notifier> notifiers) → bool | Checks if the current Notifier is attached to all the passed notifier(s). If it is then true, else false.
**hasAttachedAllThese(Iterable\<Notifier> notifiers) → Iterable\<bool> | Checks if the current Notifier isAttached to these Notifiers, while returning an Iterable\<bool> that describes the state of each Notifier in that regard.
poll(int times, {TickerProvider vsync}) → Future\<Duration> | Polls the Notifier for a fixed number of times and returns the Duration taken to poll as a return as Future.
pollFor(Duration duration, {TickerProvider vsync}) → Future\<Notifier> | Polls the Notifier over the given Duration of time. Returns the current instance as a Future.
removeListener(Function listener) → bool | Tries to remove the passed listener from the Notifier. If it was previously a listener of that Notifier it returns true, else false.
removeListenerByHashCode(int hashCode) → bool | Tries to remove a listener by it's hashCode (if a listener with that hashCode exists). If it was previously a listener of that Notifier then it returns true else false.
removeListeners(Iterable\<Function> listeners) → Iterable\<bool> | Tries to remove multiple listeners from a Notifier. For any given index, if the listener was previously a listener of that notifier, it removes it and sets true else false and finally returns the complete Iterable\<bool>.
removeListenersByHashCodes(Iterable\<int> hashCodes) → Iterable\<bool> | Tries to remove multiple listeners by their hashCode (if found). For any given index, if it is found then it's removed and true is it set for the Iterable\<bool> that'll be returned else false.
clearListeners() | Clears all the listeners of the current Notifier (including attachments and stops notifying any listener listening to it)
reverseListeningOrder() → void | Just as the name suggests, it reverses the order in which the listeners get notified.
init({Iterable\<Notifier> attachNotifiers, Iterable\<Notifier> listenToNotifiers, Iterable\<Notifier> mergeNotifiers, Iterable\<Function> initialListeners, bool removeListenerOnError(Error)}) → bool | Manually initialize the Notifier (if it's disposed). Returns true if the Notifier was previously disposed, else just does nothing and returns false. Values can be set through other methods.
dispose() → bool | Disposes the current Notifier. The Notifier can be re-init with the help of the `init()` (however the reused Notifier will be as good as using a new one). If the Notifier was already disposed it'll return false else true.

Getter methods | Description
-------------- | -----------
isDisposed → bool | Checks if the given Notifier is disposed or not. If it's disposed it returns true else false.
isNotDisposed → bool | Checks if the given Notifier is disposed or not. If it's disposed it returns false else true.
notify → Notifier | Returns the current instance as a Notifier. Generally used as `notifier.notify()`
notifyListener → Notifier | Returns the current instance as a Notifier. Generally used as `notifier.notifyListeners()`
notifyListener → Notifier | Returns the current instance as a Notifier. Generally used as `notifier.notifyListeners()`
sendNotification → Notifier | Returns the current instance as a Notifier. Generally used as `notifier.sendNotification()`
numberOfListeners → int | Returns the number of listeners that Notifier is responsible for.
**hasListeners → bool | Returns true if the Notifier has at least one listener else false.

Static method | Description
------------- | -----------
addListenerToNotifier(Notifier notifier, Function listener) → int | A static static implementation of the instance method `addListener`.
addListenersToNotifier(Notifier notifier, Iterable<Function> listeners) → Iterable<int> | Adds multiple listeners to the same Notifier. (A static implementation of the instance method `addListeners`)
clearListenersOfNotifier(Notifier notifier) → bool | Clears all the listeners of the passed Notifier. (A static implementation of the instance method `clearListeners()`)
clearListenersOfNotifiers(Iterable<Notifier> notifiers) → Iterable<bool> | Clears all the listeners of the given list of Notifiers. A static implementation of `clearListeners()` for multiple notifiers.
from(Notifier notifier) → Notifier | Instantiate a new notifier from an existing Notifier (the Notifier that was passed)
disposeNotifier(Notifier notifier) → bool | Disposes the passed Notifier. A static implementation of these instance methods
disposeNotifiers(Iterable<Notifier> notifiers) → Iterable<bool> |

## ValNotifier

## HttpNotifier 

## TimedNotifier (Needs to be implemented)

## TweenNotifier (Needs to be implemented)

## State management with notifier_plugin

## The magic of extension methods and operator overloading

[...]

For example you could,

Update the Text of a RaisedButton, when the user clicks on it (without re-building the rest of the UI tree),
```Dart
int i = 0;
~(n) => RaisedButton(child: Text((++i).toString()), onPressed: n) // A Notifier is callable just like a Function is.
```

or maybe even pass a value to that part of a tree while re-building it,
```Dart
~(n,i)=>RaisedButton(child: Text((i==null?i=1:++i).toString()), onPressed: ()=>n(i)) // A ValNotifier was used here
```

or even rebuild the UI by explicitly defining a Notifier,
```Dart
Notifier n = Notifier();
int i = 0;
// [...]
n - ()=>Text((++i).toString())
// [...]
RaisedButton(child: Text("Increment"), onPressed: n)
```

or even a ValNotifier.

```Dart
ValNotifier n = ValNotifier(initialVal: 0); // Supports explicit type-check through type-param<>, while notify a value.
// [...]
n - (i)=>Text(i.toString())
// [...]
RaisedButton(child: Text("Increment"), onPressed: ()=>n(n.val))
```

## The special case of "Notifier extends Iterable\<Notifier>"

Notifier extends Iterable<Notifier>
  
Wait what? Is that even possible?

Yes, it is.

Hmm...But why did you use it in this plugin?

Well, I was finding a way to accept one/multiple Notifier(s) through the same constructor parameter with type-check (for the `NotificationBuilder` widget). Initially, I had spend quite some time trying to find a way to make a Notifier variable accept multiple Notifier(s) through different ways, but didn't really succeed. Then I tried searching for a solution online (StackOverflow, GitHub, [pub.dev](https://www.pub.dev)), but still couldn't get anywhere close to what I was looking for. I tried using one of the plugins on pub.dev for making a single variable accept two types with type-check, but it didn't really work as expected. At the end, instead of looking for a Dart specific solution, I just started re-thinking the way OOP emulates the behavior, I was looking for and then...some light fell from nowhere and I just imagined an hierarchy (inheritance)...smiled for a while...and then implemented the solution..and it worked! For a moment, I felt that I broke OOP...but that wasn't surely something that my conscious mind would readily agree upon. I just extended Iterable<Notifier> to Notifier, implemented a method and now every variable of type `Iterable<Notifier>` can even accept a `Notifier` and work as though nothing had happened. To take things to a whole new level, I added an extension method on Iterable<Notifier> and had re-implemented all the methods available for a Notifier along with a few additional methods that could only be specific to an Iterable. This might sound silly and even funny for now, but it has proved to be useful in increasing flexibility different ways.
  
For eg. You could attach two Notifier(s) to the same widget without actually instantiating a new one that **dynamically** keeps track of the two,
```Dart
[notifier1, notifier2] - ()=> Inbox([...])
```
Actually implementing something like that would add unwanted complexity to the code, increase the learning curve and would need a bit of extra resources than the Iterable that custom object would internally hold.

Other examples:
```Dart
[notifier1, notifier2](); // notifies all the notifiers
[notifier1, notifierN].addListener(()=>print("Smile!")); // Adds a listener to all the notifiers 
[notifier1, notifierN].attach(notifier2); // attaches notifier2 to all the notifiers
[notifier1, notifierN].dispose(); // disposes all the notifiers in the list
[valNotifier1, notifier1](3); // Passes 3 to the ValNotifier and just notifies notifier1

// Side Note: Please don't try to enter the complexity of Iterable<Notifier> and Notifier at a **deeper level** unless you are not really developing a plugin/package that depends on this or are just spending some time with this plugin/Flutter. If you're developing an real application, there should always be an easier way of doing things. (Keeping the main intention of this plugin in mind)
// For example: Trying to notify a List of Notifiers that contains a disposed Notifier, dealing with atomic calls, attaching a Notifier to List of Notifiers that already contains that Notifier, and so on...
```

**Atomic calls on a List\<Notifier>**: An atomic call is a method that interfaces it's corresponding existing method to check if all the Notifiers in the Iterable are disposed or not, before trying to notify all of them. 

If you're still wondering how is all this still working..then the secret lies in the method/getter that was implemented while extending Iterable<Notifier>,
  
```Dart
get iterator => {this}.iterator;
```
  
So if you assign a Notifier to an Iterable<Notifier> it treats it as an Iterable...and that's how this magic seems to work.
  
## Last Section

A `Notifier` is a simple object that maintains and notifies a set of listeners, whenever they are asked to do so. One can attach a Notifier to another Notifier, listen to the notification events of another Notifier, or even poll a Notifier for over a fixed duration or for fixed number of times.
