import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:maava/src/presentation/branding/theme_color_provider.dart';
import 'package:maava/src/presentation/mode/app_mode.dart';
import 'package:maava/src/presentation/mode/mode_switch_button.dart';
import 'package:maava/src/quick/core/local_storage/local_storage.dart';
import 'package:maava/src/quick/di/repository_providers.dart'
    show localStorageProvider;
import 'package:shared_preferences/shared_preferences.dart';

/// The centre switch must always advertise the DESTINATION, and must read the
/// same global module state as the header switcher — otherwise the two controls
/// can disagree about which module is active, which is the bug this widget is
/// most likely to grow.
class _MemoryStorage implements LocalStorage {
  final _values = <String, Object>{};

  @override
  String? getString(String key) => _values[key] as String?;
  @override
  Future<void> setString(String key, String value) async => _values[key] = value;
  @override
  bool? getBool(String key) => _values[key] as bool?;
  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;
  @override
  List<String> getStringList(String key) =>
      (_values[key] as List<String>?) ?? const [];
  @override
  Future<void> setStringList(String key, List<String> value) async =>
      _values[key] = value;
  @override
  Future<void> remove(String key) async => _values.remove(key);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late GoRouter router;

  Future<WidgetRef> pumpButton(WidgetTester tester) async {
    late WidgetRef captured;
    // A real router: the button navigates to the destination module's home, so
    // a bare MaterialApp would not exercise what it actually does.
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        for (final path in ['/home', '/quick/home', '/mart-splash'])
          GoRoute(
            path: path,
            builder: (context, state) => const Scaffold(
              bottomNavigationBar: ModeSwitchButton(),
            ),
          ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(_MemoryStorage())],
        child: Consumer(
          builder: (context, ref, _) {
            captured = ref;
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return captured;
  }

  String location() =>
      router.routerDelegate.currentConfiguration.uri.path;

  Color discColour(WidgetTester tester) {
    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer).first,
    );
    return ((container.decoration!) as BoxDecoration).color!;
  }

  testWidgets('in Food mode it advertises Mart, in the app palette', (tester) async {
    final ref = await pumpButton(tester);
    expect(ref.read(appModeProvider), AppMode.food);

    expect(find.text('Mart'), findsOneWidget);
    expect(find.text('Food'), findsNothing, reason: 'must show the destination');
    expect(find.byIcon(Icons.shopping_basket_rounded), findsOneWidget);
    expect(discColour(tester), AppThemeColor.violet.color,
        reason: 'one global palette drives both sections');
  });

  testWidgets('in Quick mode it advertises Food, in the food palette',
      (tester) async {
    final ref = await pumpButton(tester);
    ref.read(appModeProvider.notifier).set(AppMode.quick);
    await tester.pumpAndSettle();

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Mart'), findsNothing);
    expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    expect(discColour(tester), AppThemeColor.violet.color);
  });

  testWidgets('tapping flips the shared module state, repeatedly',
      (tester) async {
    final ref = await pumpButton(tester);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(ModeSwitchButton));
      await tester.pumpAndSettle();
      expect(ref.read(appModeProvider), AppMode.quick,
          reason: 'tap $i should land in quick');
      expect(location(), '/mart-splash',
          reason: 'entering Mart plays the HiberMart opener, which then '
              'forwards to the Mart home itself');

      await tester.tap(find.byType(ModeSwitchButton));
      await tester.pumpAndSettle();
      expect(ref.read(appModeProvider), AppMode.food,
          reason: 'tap $i should land back in food');
      expect(location(), '/home', reason: 'and back to the real food home');
    }
  });
}
