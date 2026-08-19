import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../di/app_providers.dart';
import '../../../../navigation/route_paths.dart';
import '../../../common/widgets/misc/app_network_image.dart';
import '../../notifications/notifications_provider.dart';

/// The "Deliver to" bar: address selector on the left, notifications and the
/// account avatar on the right.
///
/// With no address chosen yet the row prompts for one rather than showing a
/// placeholder address — a sample street name here reads as a real saved
/// address and sends people to checkout with nothing selected.
class DeliveryHeader extends ConsumerWidget {
  const DeliveryHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(selectedAddressProvider);
    final unread = ref.watch(notificationsProvider.select((s) => s.unreadCount));
    final user = ref.watch(authProvider).user;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: context.semantic.brandSurfaceSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.location_on_rounded,
              size: 21,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(RoutePaths.addresses),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    address == null ? 'No address yet' : 'Deliver to',
                    style: context.text.bodySmall!.copyWith(fontSize: 11.5),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address == null
                              ? 'Add a delivery address'
                              : '${address.label.wireValue} - ${address.shortLine}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 19,
                        color: context.colors.onSurface,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _CircleAction(
            onTap: () => context.push(RoutePaths.notifications),
            badgeCount: unread,
            child: Icon(
              Icons.notifications_none_rounded,
              size: 22,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _CircleAction(
            onTap: () => context.push(RoutePaths.profile),
            child: user != null && user.profileImage.isNotEmpty
                ? ClipOval(
                    child: AppNetworkImage(
                      url: user.profileImage,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.person_outline_rounded,
                    ),
                  )
                : Icon(
                    Icons.person_outline_rounded,
                    size: 22,
                    color: context.colors.onSurface,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Bordered circular icon button, optionally counter-badged.
class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.onTap,
    required this.child,
    this.badgeCount = 0,
  });

  final VoidCallback onTap;
  final Widget child;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: context.colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: context.semantic.border),
            ),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: context.semantic.danger,
                  borderRadius: AppRadii.rPill,
                  border: Border.all(color: context.colors.surface, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: context.text.labelSmall!.copyWith(
                    color: context.colors.surface,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
