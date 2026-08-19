import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_commerce_user/core/local_storage/local_storage.dart';
import 'package:quick_commerce_user/core/theme/app_theme_provider.dart';
import 'package:quick_commerce_user/core/theme/app_colors.dart';
import 'package:quick_commerce_user/core/theme/app_theme.dart';
import 'package:quick_commerce_user/di/repository_providers.dart';

/// In-memory [LocalStorage] so the controller can persist without a platform
/// channel.
class _FakeStorage implements LocalStorage {
  final values = <String, Object>{};

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  String? getString(String key) => values[key] as String?;

  @override
  List<String> getStringList(String key) =>
      (values[key] as List<String>?) ?? const [];

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

/// Profile → App Theme writes `mode.name` and the next launch reads it back.
/// `System` used to be unrepresentable — the reader collapsed every unknown
/// name to light, so picking it looked like the setting did nothing.
void main() {
  ProviderContainer containerOn(_FakeStorage storage) {
    final c = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('defaults to light with nothing stored', () {
    expect(containerOn(_FakeStorage()).read(themeProvider).mode, ThemeMode.light);
  });

  for (final mode in ThemeMode.values) {
    test('$mode survives a restart', () async {
      final storage = _FakeStorage();
      await containerOn(storage).read(themeProvider.notifier).setMode(mode);

      // A fresh container is what the next launch sees.
      expect(containerOn(storage).read(themeProvider).mode, mode);
    });
  }

  test('picking a mode swaps the state immediately', () async {
    final c = containerOn(_FakeStorage());
    await c.read(themeProvider.notifier).setMode(ThemeMode.dark);
    expect(c.read(themeProvider).mode, ThemeMode.dark);
  });

  test('a corrupt stored value falls back to light instead of throwing', () {
    final storage = _FakeStorage()..values[StorageKeys.themeMode] = 'chartreuse';
    expect(containerOn(storage).read(themeProvider).mode, ThemeMode.light);
  });

  // The whole point of the setting: the pick has to repaint the running app,
  // not just land in storage waiting for a restart.
  testWidgets('the pick repaints the running app', (tester) async {
    final container = containerOn(_FakeStorage());
    late BuildContext captured;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(themeProvider);
            return MaterialApp(
              themeMode: settings.mode,
              theme: AppTheme.light(settings.flavor),
              darkTheme: AppTheme.dark(settings.flavor),
              home: Builder(
                builder: (inner) {
                  captured = inner;
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );
    expect(Theme.of(captured).brightness, Brightness.light);

    await container.read(themeProvider.notifier).setMode(ThemeMode.dark);
    // MaterialApp cross-fades through AnimatedTheme, so settle the transition
    // rather than sampling it mid-lerp.
    await tester.pumpAndSettle();
    expect(Theme.of(captured).brightness, Brightness.dark);

    // Every quick screen reads `context.semantic`, which null-asserts unless
    // the extension is registered on both ThemeDatas.
    expect(Theme.of(captured).extension<AppSemanticColors>(), isNotNull);
  });
}
