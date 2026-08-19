import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// One service promise. Purely editorial chrome — it makes no claim about a
/// product, a price or a store, so it carries no backend data.
class ServicePromise {
  const ServicePromise(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

const _promises = [
  ServicePromise(Icons.eco_outlined, 'Farm Fresh', 'Quality Produce'),
  ServicePromise(
    Icons.local_shipping_outlined,
    'Free Delivery',
    'On eligible orders',
  ),
  ServicePromise(
    Icons.lock_outline_rounded,
    'Secure Payment',
    '100% Protected',
  ),
  ServicePromise(Icons.autorenew_rounded, 'Easy Returns', 'Hassle-free'),
];

/// The four-up trust strip that sits directly under the hero banner.
class FeatureHighlightsRow extends StatelessWidget {
  const FeatureHighlightsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < _promises.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 30,
                color: context.semantic.border,
                margin: const EdgeInsets.symmetric(horizontal: 1),
              ),
            Expanded(child: _Promise(promise: _promises[i])),
          ],
        ],
      ),
    );
  }
}

class _Promise extends StatelessWidget {
  const _Promise({required this.promise});

  final ServicePromise promise;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(promise.icon, size: 16, color: context.colors.primary),
        const SizedBox(width: 4),
        // Scaled rather than ellipsised: "Secure Payment" is the promise, and
        // "Secure Pay…" reads as a defect.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  promise.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    height: 1.25,
                    letterSpacing: 0,
                    color: context.colors.onSurface,
                  ),
                ),
                Text(
                  promise.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall!.copyWith(
                    fontSize: 8,
                    height: 1.3,
                    letterSpacing: 0,
                    color: context.semantic.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The wider benefit panel that closes the home page.
class ServiceBenefitsPanel extends StatelessWidget {
  const ServiceBenefitsPanel({super.key});

  static const _benefits = [
    ServicePromise(
      Icons.verified_outlined,
      'Best Quality',
      'We deliver only the freshest, finest products.',
    ),
    ServicePromise(
      Icons.sell_outlined,
      'Affordable Prices',
      'Best prices and exclusive offers on your favourites.',
    ),
    ServicePromise(
      Icons.rocket_launch_outlined,
      'Fast Delivery',
      'Lightning-fast delivery to your doorstep, on time.',
    ),
    ServicePromise(
      Icons.shield_outlined,
      '100% Secure',
      'Your payments and data are safe with us.',
    ),
    ServicePromise(
      Icons.replay_rounded,
      'Easy Returns',
      'Not satisfied? Easy returns after delivery.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.semantic.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _benefits.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 52,
                color: context.semantic.border,
                margin: const EdgeInsets.symmetric(horizontal: 1),
              ),
            Expanded(child: _Benefit(benefit: _benefits[i])),
          ],
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.benefit});

  final ServicePromise benefit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(benefit.icon, size: 14, color: context.colors.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  benefit.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 8.5,
                    height: 1.2,
                    letterSpacing: 0,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            benefit.subtitle,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall!.copyWith(
              fontSize: 7.5,
              height: 1.35,
              letterSpacing: 0,
              color: context.semantic.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
