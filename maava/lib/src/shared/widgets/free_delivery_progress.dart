import 'package:flutter/material.dart';

/// "Get FREE delivery" with a bar showing how close the cart is to the
/// threshold, or a success line once it is cleared.
///
/// Shared by both carts so Mart and Food cannot drift apart on the same
/// promise. Every number is passed in — the threshold comes from the backend's
/// fee settings and the spend from the live cart, so the bar moves on every
/// add, remove and quantity change without this widget knowing where either
/// came from.
class FreeDeliveryProgress extends StatelessWidget {
  const FreeDeliveryProgress({
    super.key,
    required this.spent,
    required this.threshold,
    required this.formatAmount,
    this.onTap,
  });

  /// Cart value counted toward free delivery.
  final double spent;

  /// The backend's free-delivery threshold. Zero or less means the shop does
  /// not run the offer, and the section hides itself entirely.
  final double threshold;

  /// Currency formatting belongs to the host app, which already has one.
  final String Function(double amount) formatAmount;

  final VoidCallback? onTap;

  static const _blue = Color(0xFF1A6DD9);
  static const _blueSoft = Color(0xFFEAF2FE);
  static const _track = Color(0xFFD6E4F7);

  bool get _unlocked => spent >= threshold;

  double get _fraction =>
      threshold <= 0 ? 0 : (spent / threshold).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    if (threshold <= 0) return const SizedBox.shrink();
    final remaining = (threshold - spent).clamp(0.0, double.infinity);

    return Material(
      color: _blueSoft,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.electric_bolt_rounded,
                    size: 18,
                    color: _blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _unlocked
                          ? 'You unlocked FREE delivery'
                          : 'Get FREE delivery',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _blue,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: _blue,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  _unlocked
                      ? 'No delivery charge on this order'
                      : 'Add products worth ${formatAmount(remaining)} more',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  // Animated so a quantity change slides the bar rather than
                  // snapping it, which is what makes the progress readable.
                  tween: Tween(begin: 0, end: _fraction),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOut,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 5,
                    backgroundColor: _track,
                    valueColor: const AlwaysStoppedAnimation<Color>(_blue),
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
