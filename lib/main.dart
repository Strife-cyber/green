import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Warm the SharedPreferences cache so LocalStore and the locale controller
  // resolve immediately after the first frame.
  await SharedPreferences.getInstance();
  runApp(const ProviderScope(child: GreenApp()));
}
