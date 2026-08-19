import 'package:flutter/material.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/utils/app_haptics.dart';
import '../misc/quantity_stepper.dart';
import '../../../../core/theme/app_theme.dart';

/// "ADD" that morphs into a quantity stepper once the item is in the cart.
///
/// The morph is a size+fade transition on a spring curve rather than two
/// swapped widgets, so the control feels like one object changing shape.
class AnimatedAddButton extends StatelessWidget {
  const AnimatedAddButton({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    this.enabled = true,
    this.hasVariants = false,
    this.canIncrement = true,
    this.height = 32,
    this.width = 78,
    this.compact = true,
    this.expand = false,
  });

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool enabled;

  /// Variant products open a sheet instead of adding directly; the button says
  /// so with a small chevron.
  final bool hasVariants;
  final bool canIncrement;
  final double height;
  final double width;
  final bool compact;

  /// Stretches the control to its parent's width and switches the add state to
  /// the outlined "ADD TO CART" call to action used on product cards.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppDurations.medium,
      curve: Curves.easeOutBack,
      alignment: expand ? Alignment.center : Alignment.centerRight,
      child: AnimatedSwitcher(
        duration: AppDurations.medium,
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: quantity > 0
            ? SizedBox(
                key: const ValueKey('stepper'),
                height: height,
                child: QuantityStepper(
                  quantity: quantity,
                  height: height,
                  compact: compact,
                  canIncrement: canIncrement,
                  onIncrement: onIncrement,
                  onDecrement: onDecrement,
                ),
              )
            : _AddPill(
                key: const ValueKey('add'),
                expand: expand,
                // Add to cart is a committing action → medium. Placed on the
                // pill (not on `CartActions.add`) so batch adds like "add all
                // in-stock" fire once, not once per item.
                onTap: enabled
                    ? () {
                        AppHaptics.medium();
                        onAdd();
                      }
                    : null,
                hasVariants: hasVariants,
                height: height,
                width: width,
              ),
      ),
    );
  }
}

class _AddPill extends StatefulWidget {
  const _AddPill({
    super.key,
    required this.onTap,
    required this.hasVariants,
    required this.height,
    required this.width,
    required this.expand,
  });

  final VoidCallback? onTap;
  final bool hasVariants;
  final double height;
  final double width;
  final bool expand;

  @override
  State<_AddPill> createState() => _AddPillState();
}

class _AddPillState extends State<_AddPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Add to cart',
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1,
          duration: AppDurations.instant,
          child: widget.expand
              ? _outlinedCta(context, enabled: enabled)
              : _pill(context, enabled: enabled),
        ),
      ),
    );
  }

  /// The card CTA: outlined, brand-coloured, full width.
  Widget _outlinedCta(BuildContext context, {required bool enabled}) {
    final tint = enabled ? context.colors.primary : context.semantic.textSecondary;
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: enabled ? tint : context.semantic.border),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              'ADD TO CART',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall!.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.3,
                color: tint,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            widget.hasVariants
                ? Icons.expand_more_rounded
                : Icons.shopping_cart_outlined,
            size: 13,
            color: tint,
          ),
        ],
      ),
    );
  }

  /// The compact pill used everywhere a card CTA would not fit.
  Widget _pill(BuildContext context, {required bool enabled}) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: enabled ? context.colors.primary : context.semantic.border,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Add',
            style: context.text.labelSmall!.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: context.colors.onPrimary,
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            widget.hasVariants ? Icons.expand_more_rounded : Icons.add_rounded,
            size: 15,
            color: context.colors.onPrimary,
          ),
        ],
      ),
    );
  }
}
