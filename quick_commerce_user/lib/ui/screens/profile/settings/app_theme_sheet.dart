import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../core/utils/app_haptics.dart';

/// Profile → App Theme. Light / Dark / System, applied the moment it is
/// tapped and persisted by [ThemeController].
Future<void> showAppThemeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AppThemeSheet(),
  );
}

class _AppThemeSheet extends ConsumerWidget {
  const _AppThemeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider).mode;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadii.sheetTop,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Theme', style: context.text.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            for (final option in const [
              (ThemeMode.light, 'Light', Icons.light_mode_rounded),
              (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
              (
                ThemeMode.system,
                'System default',
                Icons.settings_brightness_rounded
              ),
            ])
              _Option(
                mode: option.$1,
                label: option.$2,
                icon: option.$3,
                selected: mode == option.$1,
              ),
          ],
        ),
      ),
    );
  }
}

class _Option extends ConsumerWidget {
  const _Option({
    required this.mode,
    required this.label,
    required this.icon,
    required this.selected,
  });

  final ThemeMode mode;
  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tint = selected ? context.colors.primary : context.semantic.textSecondary;
    return ListTile(
      leading: Icon(icon, color: tint),
      title: Text(
        label,
        style: context.text.titleMedium!.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: context.colors.primary)
          : null,
      onTap: () {
        AppHaptics.selection();
        ref.read(themeProvider.notifier).setMode(mode);
        Navigator.pop(context);
      },
    );
  }
}
