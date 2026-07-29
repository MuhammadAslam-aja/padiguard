import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/providers/core_providers.dart';
import 'services/shared_prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  final sharedPrefsService = SharedPrefsService(sharedPreferences);

  runApp(
    ProviderScope(
      overrides: [
        // Inject the initialized SharedPreferences service
        sharedPrefsProvider.overrideWithValue(sharedPrefsService),
      ],
      child: const MyApp(),
    ),
  );
}
