import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../common/widgets/feedback/app_dialog.dart';

import '../../core/constants/app_durations.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../di/app_providers.dart';
import '../common/widgets/misc/fly_to_cart.dart';

/// Bottom navigation for the five top-level destinations, with the delivery
/// promise raised into a centre badge that doubles as the cart entry point.
///
/// The badge carries [cartAnchorKey] so the fly-to-cart animation knows where
/// to land from anywhere in the app.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// The visual order differs from the router's branch order, so each item
  /// names its branch explicitly rather than relying on position.
  /// Router branches: 0 home · 1 categories · 2 cart · 3 orders · 4 profile.
  static const _cartBranchIndex = 2;
  static const _homeBranchIndex = 0;

  static const _left = [
    (0, Icons.home_outlined, Icons.home_rounded, 'Home'),
    (1, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Categories'),
  ];

  static const _right = [
    (3, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders'),
    (4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);
    final current = navigationShell.currentIndex;

    // Back on a tab root used to fall straight through to the OS and close the
    // app — there is nothing above the shell to pop, and switching tabs with
    // `go` leaves no history entry behind. Only Home is allowed to exit, and
    // only after asking.
    //
    // Screens pushed on top of the shell (product, order details, checkout …)
    // are separate routes on the root navigator, so their back press is handled
    // by the Navigator and never reaches this callback. Deep links are
    // unaffected for the same reason.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (current != _homeBranchIndex) {
          // Any other tab returns to Home first, the way a back press is
          // expected to behave on Android.
          _go(_homeBranchIndex);
          return;
        }
        await _confirmExit(context);
      },
      child: _scaffold(context, cartCount, current),
    );
  }

  /// Home is the only place the app may be closed from, and never silently.
  Future<void> _confirmExit(BuildContext context) async {
    final shouldExit = await AppDialog.confirm(
      context,
      icon: Icons.exit_to_app_rounded,
      title: 'Do you want to exit the app?',
      message: 'Your cart is saved and will be waiting when you come back.',
      confirmLabel: 'Exit',
      cancelLabel: 'Cancel',
    );
    if (!shouldExit) return;

    // `SystemNavigator.pop` backs out of the app the way the OS expects,
    // leaving it resumable from Recents. `exit(0)` would kill the process and
    // is what Android's own guidance warns against.
    await SystemNavigator.pop();
  }

  Widget _scaffold(BuildContext context, int cartCount, int current) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.semantic.border)),
          boxShadow: context.semantic.sheetShadow,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                for (final item in _left)
                  Expanded(
                    child: _NavItem(
                      spec: item,
                      selected: current == item.$1,
                      onTap: () => _go(item.$1),
                    ),
                  ),
                Expanded(
                  child: _CentreBadge(
                    count: cartCount,
                    onTap: () => _go(_cartBranchIndex),
                  ),
                ),
                for (final item in _right)
                  Expanded(
                    child: _NavItem(
                      spec: item,
                      selected: current == item.$1,
                      onTap: () => _go(item.$1),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _go(int index) {
    // Only cue an actual tab change — re-tapping the current tab (which just
    // pops to its root) should not buzz.
    if (index != navigationShell.currentIndex) AppHaptics.selection();
    navigationShell.goBranch(
      index,
      // Tapping the active tab pops it back to its root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  /// (branch index, unselected icon, selected icon, label)
  final (int, IconData, IconData, String) spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? context.colors.primary : context.semantic.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: spec.$4,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? spec.$3 : spec.$2, size: 23, color: color),
            const SizedBox(height: 3),
            Text(
              spec.$4,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall!.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 4),
            // The active-tab underline from the reference nav.
            Container(
              height: 2.5,
              width: selected ? 22 : 0,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The raised disc: the delivery promise, and the cart's entry point.
class _CentreBadge extends StatelessWidget {
  const _CentreBadge({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: count > 0 ? 'Cart, $count items' : 'Cart',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: const Offset(0, -12),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      key: cartAnchorKey,
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.colors.surface,
                          width: 4,
                        ),
                        boxShadow: context.semantic.floatingShadow,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.shopping_cart_rounded,
                        size: 25,
                        color: context.colors.onPrimary,
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(count),
                          tween: Tween(begin: 0.6, end: 1),
                          duration: AppDurations.medium,
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 1,
                            ),
                            constraints: const BoxConstraints(minWidth: 18),
                            decoration: BoxDecoration(
                              color: context.semantic.danger,
                              borderRadius: AppRadii.rPill,
                              border: Border.all(
                                color: context.colors.surface,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: context.text.labelSmall!.copyWith(
                                color: context.colors.surface,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: Text(
                  'Cart',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall!.copyWith(
                    color: context.semantic.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
