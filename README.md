# notifier_plugin

A Flutter plugin makes state management and building dynamic UIs easier and more efficient than ever!

Please don't use this plugin in production code (until this line is removed).

(The complete documentation will soon be added!)

## Overview

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

`notifier_plugin` is a plugin that provides different classes and extension methods + operator overloading (for widgets), in order to enable developers to swiftly develop dynamic user-interfaces (in Flutter) with minimal effort. The plugin can then be combined with (custom classes that contain) simple/complex declarations to manage the state of your app in your own way. The plugin was purely made with the intention of doing things in the most simple and efficient way possible, while using minimal or no (extra) resources to implement different concepts.

For now, this plugin mainly four types of Notifiers: `Notifier`, `ValNotifier`, `SelfNotifier`, `HttpNotifier`.

[Notifier](#notifier): It's a simple object that can maintain and notify a set of listeners. One could even attach a `Notifier` to it or listen to another `Notifier`. (Note: One cannot attach a Notifier to itself or listen to itself, as that would lead to infinite recursion).

[ValNotifier](#valnotifier): It is a `Notifier` that decides to take a step ahead and maintain it's own buffer and actually pass the value to it's listeners (if it can accept one). (Note: A `Notifier` can be called with a value, but it's listeners won't get that value or get null, if they can accept one. This was done to ensure that `ValNotifier` can actually extend `Notifier` while overriding the same set of methods that are used to notify a `Notifier`)

[SelfNotifier](#selfnotifier): It is `ValNotifier`, that just notifies itself (passes itself to the listeners) when called.

[HttpNotifier](#httpnotifier): It is a special `Notifier` that maintains a separate buffer for the parameters of a HTTP request so as to avoid boiler-plate code, while performing those requests with same or similar parameters in different sections of the same app. Since a `HttpNotifier` is a `ValNotifier`, the  methods of `ValNotifier` can still be used, while using a `HttpNotifier`. The real benefit of using an (Http)Notifier can come by using it as a `Stream`. (Note: A `Notifier` is not a `Stream`)

These `Notifier`(s) and the extension methods used on certain pre-defined types, overload certain operator methods in a specific way to help developers quickly implement dynamic UI in Flutter in a scalable manner with minimal effort/code. (Read more about it in [this section](#the-magic-of-extension-methods-and-operator-overloading).)

Not sure with how you can use this plugin for state management? [This section](#state-management-with) might be a small help you. 

Also, it might be worth reading the [special case of Notifier extends Iterable\<Notifier>](#the-special-case-of-notifier-extends-iterablenotifier) used in this plugin.

## Notifier

#### Short Introduction

A `Notifier` is a simple object that maintains and notifies a set of listeners, whenever they are asked to do so. One can attach a Notifier to another Notifier, listen to the notification events of another Notifier, or even poll a Notifier for over a fixed duration or for fixed number of times.

#### Instantiating a Notifier

```
// Notifier({Iterable<Notifier> attachNotifiers, Iterable<Notifier> listenToNotifiers, Iterable<Notifier> mergeNotifiers, Iterable<Function> initialListeners, bool removeListenerOnError(Error)}); // Main Constructor
```

**attachNotifiers**: Attach these Notifier(s) to the Notifier that's being instantiated.
**listenToNotifiers**: Make the Notifier that is being instantiated listen to these Notifier(s).
**mergeNotifiers**: Merge the listeners of these Notifier(s) while instantiating this Notifier.
**initialListeners**: Pass a set of listeners to be merged to the default set of listeners.
**removeListenerOnError**: A special parameter that accepts a function that can be used to handle anything that gets thrown while notifying the listeners/even remove them (if needed) (if this function returns `true` the listener gets removed; if it returns `false` then nothing really happens; and if it returns `null`, the error simply gets `rethrown`)

The constructor automatically initializes the Notifier. (init)

#### Adding listener(s) to a Notifier

Adding a listener to a notifier is just as good as just adding a function to a list that can only hold functions. The two accepted types of `Function`s is a function that accepts nothing or function that accepts a single parameter. (Note: For the default type of Notifier, the parameter always recieves a null)

This can be done with the help of two methods, namely,

  a. **addListener**  (Accepts a Listener/Function; returns the hashCode of that listener if the function gets successfully added, else null)
  b. **addListeners** (Accepts an Iterable<Listener/Function>; returns an Iterable<int> of hashCodes. The success of adding of each method can be determined by the value at it's corresponding index in the Iterable)

```Dart
Notifier n = Notifier(); // Instantiating a Notifier
n.addListener(()=>print("Notified!")); // Adding a single listener to the Notifier
n.addListener((v)=>print("null==$v")); // Adding a single listener to the Notifier (that accepts a parameter)
n.addListeners([()=>print(1),(v)=>print("This is $v.")]); // Adding multiple listeners to the same Notifier with the help of an Iterable
```

#### Calling a Notifier


#### Polling a Notifier

#### Attaching a Notifier

#### Listening to a Notifier

#### Calling a specific listener

#### Removing listener(s) from a Notifier

A listener can be removed from a Notifier in two ways:

 a. By reference(s)
 
 You could just simply use the `removeListener()` method while passing the listener itself to remove it from an undisposed Notifier.
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
 
 b.
 

#### Clearing the listener(s) of the Notifier

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

#### Initializing a Notifier (init)

Generally, a disposed object cannot be used again. However, that's not the case with a Notifier. You can re-init a Notifier once it's disposed, and that's what that `init` method was made for. However, it's highly recommended that you don't dispose it until you are completely done with and use the instance method `clearListeners()` to clear all the listeners in one go. The `init()` method was just created with the intention of being able to bring the Notifier for whatever reasons.

```Dart
Notifier n = Notifier(); // auto-init()

n.dispose(); // Disposing the Notifier n

// Trying to call almost any method or getter, would throw an StateError here.

n.init(/*[...]*/); // init()
```

#### Disposing a Notifier

Disposing a Notifier generally just sets all it's members to null and does not have any special case of resource de-allocation. Once the notifier is disposed, trying to call almost any method or getter on it would throw an (State)Error. A disposed Notifier can be re-init with the help of the init() method.

```Dart
Notifier n = Notifier();

// Use the notifier for a while

n.dispose(); // Disposing the Notifier n

n.clearListeners(); // throws a StateError
```

## ValNotifier

## SelfNotifier

## HttpNotifier

## State management with notifier_plugin

## The magic of extension methods and operator overloading

[...]

For example you could,

Update the Text of a RaisedButton, when the user clicks on it (without re-building the rest of the UI tree),
```Dart
int i = 0;
~(n)=>RaisedButton(child: Text((++i).toString()), onPressed: n) // A Notifier is callable just like a Function is.
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
