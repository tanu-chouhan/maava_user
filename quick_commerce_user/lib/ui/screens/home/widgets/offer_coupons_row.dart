import 'package:flutter/material.dart';

import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/model/coupon.dart';
import '../../../common/widgets/loaders/shimmer_box.dart';

/// The promo block under the category strip: the first live offer as a full
/// feature card, the second as a compact companion.
///
/// Every word on these cards is derived from the coupon the backend returned —
/// with no offers published the block renders nothing rather than inventing a
/// promotion no merchant has made.
class OfferCouponsRow extends StatelessWidget {
  const OfferCouponsRow({
    super.key,
    this.coupons = const [],
    this.isLoading = false,
    this.onOfferTap,
  });

  final List<Coupon> coupons;
  final bool isLoading;
  final ValueChanged<Coupon>? onOfferTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading && coupons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            Expanded(flex: 62, child: ShimmerBox(height: 168)),
            SizedBox(width: AppSpacing.sm),
            Expanded(flex: 38, child: ShimmerBox(height: 168)),
          ],
        ),
      );
    }

    if (coupons.isEmpty) return const SizedBox.shrink();

    final feature = coupons.first;
    final companion = coupons.length > 1 ? coupons[1] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: companion == null ? 1 : 62,
              child: _FeatureOfferCard(
                coupon: feature,
                onTap: () => onOfferTap?.call(feature),
              ),
            ),
            if (companion != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 38,
                child: _CompanionOfferCard(
                  coupon: companion,
                  onTap: () => onOfferTap?.call(companion),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Up to 30% off" / "₹150 off" — whichever the coupon actually is.
String _discountLabel(Coupon coupon) => switch (coupon.discountType) {
      DiscountType.percentage => '${coupon.discountValue.toStringAsFixed(0)}%\nOFF',
      DiscountType.flat => '${coupon.discountValue.asCurrency}\nOFF',
    };

/// The qualifying line, only when the backend set a threshold.
String _termsLine(Coupon coupon) {
  final parts = <String>[
    if (coupon.minOrderValue > 0) 'on orders over ${coupon.minOrderValue.asCurrency}',
    if (coupon.isFirstOrderOnly) 'first order only',
    if (coupon.sellerName.trim().isNotEmpty) 'at ${coupon.sellerName.trim()}',
  ];
  return parts.isEmpty ? 'Apply code ${coupon.code} at checkout' : parts.join(' · ');
}

class _FeatureOfferCard extends StatelessWidget {
  const _FeatureOfferCard({required this.coupon, required this.onTap});

  final Coupon coupon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onPlate = context.semantic.onBrandSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.semantic.brandSurface,
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    coupon.isExpired ? 'OFFER' : 'LIMITED TIME OFFER',
                    style: context.text.labelSmall!.copyWith(
                      color: onPlate.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _OfferHeadline(title: coupon.title, onPlate: onPlate),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _termsLine(coupon),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall!.copyWith(
                      color: onPlate.withValues(alpha: 0.82),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PlateButton(
                    label: 'SHOP NOW',
                    background: context.colors.surface,
                    foreground: context.colors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                color: context.semantic.warning,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _discountLabel(coupon),
                textAlign: TextAlign.center,
                style: context.text.labelMedium!.copyWith(
                  color: AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanionOfferCard extends StatelessWidget {
  const _CompanionOfferCard({required this.coupon, required this.onTap});

  final Coupon coupon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.semantic.brandSurfaceSoft,
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              coupon.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleMedium!.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                height: 1.2,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _termsLine(coupon),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall!.copyWith(fontSize: 10.5, height: 1.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: _PlateButton(
                label: 'ORDER NOW',
                background: context.colors.primary,
                foreground: context.colors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlateButton extends StatelessWidget {
  const _PlateButton({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall!.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.arrow_forward_rounded, size: 13, color: foreground),
        ],
      ),
    );
  }
}

/// "Weekend / Super Saver" — first half in the plate ink, the rest in the
/// accent, split on the coupon's own wording.
class _OfferHeadline extends StatelessWidget {
  const _OfferHeadline({required this.title, required this.onPlate});

  final String title;
  final Color onPlate;

  @override
  Widget build(BuildContext context) {
    final words = title.trim().split(RegExp(r'\s+'))..removeWhere((w) => w.isEmpty);
    final cut = words.length < 2 ? words.length : (words.length / 2).ceil();
    final first = words.take(cut).join(' ');
    final rest = words.skip(cut).join(' ');

    final style = context.text.displaySmall!.copyWith(
      fontWeight: FontWeight.w800,
      fontSize: 18,
      height: 1.15,
      letterSpacing: -0.3,
    );

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style.copyWith(color: onPlate),
        children: [
          TextSpan(text: first),
          if (rest.isNotEmpty)
            TextSpan(
              text: '\n$rest',
              style: style.copyWith(color: context.semantic.accent),
            ),
        ],
      ),
    );
  }
}
