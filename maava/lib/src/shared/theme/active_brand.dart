import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/branding/app_colors.dart';
import '../../presentation/branding/theme_color_provider.dart';

/// The brand colour of whichever module is active.
///
/// The shared screens — Profile, Orders, Addresses, Notifications, Settings,
/// Help, the legal pages — have exactly ONE implementation each, authored on
/// the food side, and they read [AppColors.primary] rather than a theme from
/// their subtree. That static is what makes them uniformly branded; making it
/// follow the active module is therefore what makes the same screen render
/// violet under Food and teal under Quick, with no second copy of anything.
///
/// Food keeps whatever palette the user picked in Profile → App Theme (violet
/// by default); Quick always uses its own brand teal, since its palette is
/// chosen in Quick's own Settings and drives its themed subtree already.
///
/// This is the single writer of [AppColors.primary]. `ThemeColorNotifier` only
/// records the user's choice — two writers would race, and whichever ran last
/// would silently win.
class ActiveBrand {
  const ActiveBrand({required this.primary, required this.button});

  final Color primary;
  final Color button;
}

final activeBrandProvider = Provider<ActiveBrand>((ref) {
  final foodPalette = ref.watch(themeColorProvider);

  // ONE palette for the whole app. Food and Mart deliberately share it: the
  // App Theme picker in Profile is a single global setting, so a colour chosen
  // in either section repaints both. Mart's teal is still in the list — it is
  // now a choice rather than a fixed per-module brand.
  final brand = ActiveBrand(
    primary: foodPalette.color,
    button: foodPalette.buttonColor,
  );

  // Applied here rather than in a listener so the values are in place before
  // the widgets that read them rebuild: every `AppColors.primary` read site
  // (roughly 600 of them) picks the new brand up in the same frame, which is
  // what makes the switch immediate rather than one-frame-late.
  AppColors.primary = brand.primary;
  AppColors.primaryButton = brand.button;
  return brand;
});
