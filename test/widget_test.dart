import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hama_padi/app.dart';
import 'package:hama_padi/core/providers/core_providers.dart';
import 'package:hama_padi/services/shared_prefs.dart';

void main() {
  testWidgets('App boots successfully and displays splash title', (WidgetTester tester) async {
    // Mock initial preferences
    SharedPreferences.setMockInitialValues({
      'is_first_time': true, // Simulating first time launch
    });
    
    final sharedPreferences = await SharedPreferences.getInstance();
    final sharedPrefsService = SharedPrefsService(sharedPreferences);

    // Build our app and trigger a frame inside ProviderScope
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(sharedPrefsService),
        ],
        child: const MyApp(),
      ),
    );

    // Trigger frame for splash animation
    await tester.pump();

    // Verify that Splash Page displays the application title PadiGuard
    expect(find.text('PadiGuard'), findsOneWidget);
  });
}
