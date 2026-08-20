import '../../../../core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/app_providers.dart';
import '../../../../navigation/route_paths.dart';
import '../../../../../presentation/auth/viewmodels/auth_viewmodel.dart';
import '../../notifications/notifications_provider.dart';

/// Mart's top bar.
///
/// - Left: a soft brand tile with the location pin, a muted "Deliver to"
///   caption, and the delivery address on one bold line with a dropdown caret.
/// - Right: notification bell with unread badge, then the account button.
///
/// Sits on the app surface rather than over the hero artwork: the address is
/// the most-read line on the screen and white-on-photo made it depend on
/// whichever banner happened to be showing.
class DeliveryHeader extends ConsumerWidget {
  const DeliveryHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(selectedAddressProvider);
    final unread = ref.watch(notificationsProvider.select((s) => s.unreadCount));
    // Same identity as Food: one account, one avatar. Mart was rendering a
    // static person glyph, so a signed-in customer never saw their own photo.
    final avatarUrl = ref.watch(authViewModelProvider).value?.avatarUrl ?? '';

    final String line;
    if (address != null && address.shortLine.trim().isNotEmpty) {
      final label = address.label.wireValue.trim();
      final short = address.shortLine.trim();
      line = label.isNotEmpty ? '$label - $short' : short;
    } else {
      line = 'Select Location';
    }

    return Container(
      color: context.colors.surface,
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 4, 12, 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 38,
            child: Icon(
              Icons.location_on_rounded,
              size: 26,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(width: 6),

          Expanded(
            child: GestureDetector(
              onTap: () => context.push(RoutePaths.addresses),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Deliver to',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          line,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            color: context.colors.onSurface,
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

          _CircleAction(
            icon: Icons.notifications_none_rounded,
            // The real unread count, nothing else. This used to fall back to
            // a literal 3 when the count was 0 — i.e. it showed a badge
            // *exactly* when there was nothing to read. _CircleAction hides
            // the badge entirely at 0.
            badge: unread,
            onTap: () => context.push(RoutePaths.notifications),
          ),
          const SizedBox(width: 8),
          _CircleAction(
            icon: Icons.person_outline_rounded,
            imageUrl: avatarUrl,
            onTap: () => context.push(RoutePaths.profile),
          ),
        ],
      ),
    );
  }
}

/// Bordered circular icon button, with an optional unread count.
class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.badge = 0,
    this.imageUrl = '',
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  /// Profile photo. Empty for signed-out users, or when the account has none —
  /// both fall back to the same bundled avatar Food uses, then to [icon] if
  /// even that fails to decode.
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            clipBehavior: imageUrl.isEmpty ? Clip.none : Clip.antiAlias,
            child: imageUrl.isEmpty
                ? Icon(icon, size: 21, color: context.colors.onSurface)
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Image.asset(
                      'assets/images/user_avatar_3d.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Icon(
                        icon,
                        size: 21,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ),
          ),
          if (badge > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: context.colors.surface, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: context.text.labelSmall!.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
