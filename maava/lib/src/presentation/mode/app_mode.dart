import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../quick/di/repository_providers.dart' as quick_di;

/// Which MAAVA vertical the user is browsing. One account, one address book,
/// one wallet — but each mode keeps its own home, catalog, cart and checkout.
enum AppMode { food, quick }

/// Last-used mode, persisted so the app reopens where the user left off.
class AppModeNotifier extends Notifier<AppMode> {
  static const _key = 'app.mode';

  @override
  AppMode build() =>
      ref.read(quick_di.localStorageProvider).getString(_key) == 'quick'
          ? AppMode.quick
          : AppMode.food;

  void set(AppMode mode) {
    state = mode;
    ref.read(quick_di.localStorageProvider).setString(_key, mode.name);
  }
}

final appModeProvider =
    NotifierProvider<AppModeNotifier, AppMode>(AppModeNotifier.new);

/// Home route for a mode — where the switcher and the splash screen land.
String homePathFor(AppMode mode) =>
    mode == AppMode.quick ? '/quick/home' : '/home';
