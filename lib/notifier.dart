library notifier;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

/// Contains declarations that can be used by notifier.dart
part 'src/init.dart';

/// Contains builder Widget(s) that interface certain Notifiers
part 'src/notification_builder.dart';

/// Contains different Notifier(s) and extensions
part 'src/notifier.dart';

//const dynamic _noArgs = const Object();
