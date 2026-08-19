import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/branding/theme_color_provider.dart';
import 'app_colors.dart';
import 'app_theme.dart';

/// Applies the quick-commerce module's own [ThemeData] to its subtree.
///
/// The MAAVA `MaterialApp` is themed for the food vertical, and quick screens
/// depend on this module's component themes and the [AppSemanticColors]
/// extension — without this scope, `context.semantic` falls back to defaults on
/// a theme that never registered the extension.
///
/// The brand comes from [themeColorProvider] — the single app-wide palette
/// App Theme writes. It used to come from a second, module-private flavour
/// setting that the Profile picker never touched, so choosing a palette
/// repainted the shared screens and left every mart screen on the default teal.
/// Light/dark still follows the app-wide ambient brightness so the two
/// verticals never disagree on dark mode.
class QuickThemeScope extends ConsumerWidget {
  const QuickThemeScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themeColorProvider);
    final brand = QuickBrand(seed: palette.color, accent: palette.buttonColor);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: dark ? AppTheme.dark(brand) : AppTheme.light(brand),
      child: child,
    );
  }
}
