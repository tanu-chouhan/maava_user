import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maava/src/presentation/branding/app_colors.dart';
import 'package:maava/src/presentation/branding/theme_color_provider.dart';
import 'package:maava/src/presentation/mode/app_mode.dart';
import 'package:maava/src/shared/theme/active_brand.dart';
import 'package:maava/src/quick/core/local_storage/local_storage.dart';
import 'package:maava/src/quick/di/repository_providers.dart'
    show localStorageProvider;
import 'package:shared_preferences/shared_preferences.dart';

/// AppModeNotifier persists through quick's LocalStorage; back it with memory.
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

/// Profile's "App Theme" row is ONE global setting for the whole app: a colour
/// picked there must repaint Food *and* Mart. The two modules briefly had
/// separate palette states, which meant a pick in one section left the other
/// on its old colour.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a palette pick applies in Mart', () async {
    final c = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(_MemoryStorage())],
    );
    addTearDown(c.dispose);
    c.read(appModeProvider.notifier).set(AppMode.quick);

    await c.read(themeColorProvider.notifier).setColor(AppThemeColor.pink);
    c.read(activeBrandProvider);
    expect(AppColors.primary, AppThemeColor.pink.color);
  });

  test('the same pick applies in Food — one global palette', () async {
    final c = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(_MemoryStorage())],
    );
    addTearDown(c.dispose);

    await c.read(themeColorProvider.notifier).setColor(AppThemeColor.blue);

    c.read(appModeProvider.notifier).set(AppMode.food);
    c.read(activeBrandProvider);
    expect(AppColors.primary, AppThemeColor.blue.color);

    // Switching section must NOT change the colour — this is the regression
    // that a per-module palette reintroduces.
    c.read(appModeProvider.notifier).set(AppMode.quick);
    c.read(activeBrandProvider);
    expect(AppColors.primary, AppThemeColor.blue.color,
        reason: 'the palette must survive a Food <-> Mart switch');
  });

  test('teal is selectable as a palette', () {
    expect(AppThemeColor.values.map((v) => v.name), contains('teal'));
  });
}
