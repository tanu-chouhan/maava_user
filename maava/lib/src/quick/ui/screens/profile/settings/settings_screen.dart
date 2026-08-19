import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../di/push_providers.dart';
import '../../../../../presentation/branding/theme_color_provider.dart';
import '../../../../../presentation/branding/theme_provider.dart' as app_theme;
import '../../../../../presentation/branding/theme_color_provider.dart' as app_palette;
import '../../../../core/local_storage/local_storage.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../di/repository_providers.dart';
import '../../../common/widgets/misc/section_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Brightness is app-wide in MAAVA, and the brand is whatever Profile →
    // App Theme recorded for quick. Both are read from their one owner here
    // rather than mirrored into a module-private copy that could drift.
    final mode = ref.watch(app_theme.themeProvider);
    final palette = ref.watch(app_palette.themeColorProvider);
    final storage = ref.watch(localStorageProvider);
    final notificationsOn =
        storage.getBool(StorageKeys.notificationsEnabled) ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            const SectionHeader(title: 'Appearance'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_rounded),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_rounded),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.settings_brightness_rounded),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (selection) {
                  AppHaptics.selection();
                  ref
                      .read(app_theme.themeProvider.notifier)
                      .setTheme(switch (selection.first) {
                        ThemeMode.dark => 'Dark',
                        ThemeMode.system => 'System',
                        ThemeMode.light => 'Light',
                      });
                },
              ),
            ),
            const SectionHeader(
              title: 'Brand colour',
              subtitle: 'Pick the palette that suits you',
            ),
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                itemCount: AppThemeColor.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final option = AppThemeColor.values[index];
                  return _FlavorSwatch(
                    option: option,
                    selected: palette == option,
                    // The same writer Profile → App Theme uses, so the two
                    // entry points cannot disagree.
                    onTap: () => ref
                        .read(app_palette.themeColorProvider.notifier)
                        .setColor(option),
                  );
                },
              ),
            ),
            const SectionHeader(title: 'Notifications'),
            SwitchListTile.adaptive(
              value: notificationsOn,
              title: Text('Order updates', style: context.text.titleMedium),
              subtitle: Text(
                'Packing, dispatch and delivery alerts',
                style: context.text.bodySmall,
              ),
              onChanged: (value) async {
                AppHaptics.selection();
                await storage.setBool(StorageKeys.notificationsEnabled, value);
                final push = ref.read(pushServiceProvider);
                if (value) {
                  // Re-register: turning the switch off dropped the token, so
                  // the backend has no way to reach this device until it is
                  // sent again.
                  await push.registerToken();
                } else {
                  await push.unregisterToken();
                }
                // Rebuild so the switch reflects what was actually persisted.
                ref.invalidate(localStorageProvider);
              },
            ),
            const SectionHeader(title: 'App'),
            ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text('Language', style: context.text.titleMedium),
              subtitle: Text('English (India)', style: context.text.bodySmall),
              trailing: Text('Default', style: context.text.bodySmall),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text('App version', style: context.text.titleMedium),
              trailing: Text('1.0.0 (1)', style: context.text.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlavorSwatch extends StatelessWidget {
  const _FlavorSwatch({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppThemeColor option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppRadii.rLg,
          border: Border.all(
            color: selected ? option.color : context.semantic.border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Dot(color: option.color, size: 26),
                const SizedBox(width: AppSpacing.xs),
                _Dot(color: option.buttonColor, size: 18),
                const Spacer(),
                if (selected)
                  Icon(Icons.check_circle_rounded, size: 17, color: option.color),
              ],
            ),
            const Spacer(),
            Text(
              option.label,
              maxLines: 2,
              style: context.text.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        height: size,
        width: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
