import '../../../../core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/service_providers.dart';

/// One value proposition: an icon over a bold headline and a supporting line.
class ValueProp {
  const ValueProp(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
}

/// The compact four-up trust strip sitting under the hero banner.
///
/// These are service promises, not catalogue data, so the copy is part of the
/// UI — with one exception: the free-delivery threshold is a real number the
/// backend owns, read from `feeSettings` rather than typed in, so the promise
/// here can never drift from what the cart actually charges.
class TrustStrip extends ConsumerWidget {
  const TrustStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threshold = ref.watch(feeSettingsProvider).value?.freeDeliveryThreshold;

    final props = [
      const ValueProp(Icons.eco_outlined, 'Farm Fresh', 'Quality Produce'),
      ValueProp(
        Icons.local_shipping_outlined,
        'Free Delivery',
        // Until the real threshold loads, promise nothing specific.
        threshold == null
            ? 'On qualifying orders'
            : 'On orders over ₹${threshold.toStringAsFixed(0)}',
      ),
      const ValueProp(Icons.lock_outline_rounded, 'Secure Payment', '100% Protected'),
      const ValueProp(Icons.autorenew_rounded, 'Easy Returns', '7 Days Return'),
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(AppSpacing.gutter, 4, AppSpacing.gutter, 2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.semantic.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < props.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 34, color: const Color(0xFFE5E7EB)),
            Expanded(child: _Cell(prop: props[i])),
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.prop});
  final ValueProp prop;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(prop.icon, size: 20, color: context.colors.primary),
        const SizedBox(height: 5),
        Text(
          prop.title,
          textAlign: TextAlign.center,
          // Two lines, not one: "Secure Payment" does not fit a quarter-width
          // cell on a 1080px screen and was rendering as "Secure Payme…".
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelSmall!.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.1,
            fontSize: 10,
            color: context.colors.onSurface,
          ),
        ),
        Text(
          prop.subtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelSmall!.copyWith(
            fontSize: 9,
            height: 1.15,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
