import 'package:flutter/material.dart';

/// Continuous subtle vertical bounce/pop animation for section headings:
///
/// - Upward pop (-4.5px, scale 1.04) with smooth ease-out curve.
/// - Spring return to original position (0px, scale 1.0) with natural bounce.
/// - Brief resting pause phase before repeating.
/// - Total loop cycle ~2.2 seconds.
class BouncingHeading extends StatefulWidget {
  const BouncingHeading({super.key, required this.child});

  final Widget child;

  @override
  State<BouncingHeading> createState() => _BouncingHeadingState();
}

class _BouncingHeadingState extends State<BouncingHeading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        double dy = 0.0;
        double scale = 1.0;

        if (t <= 0.35) {
          // Upward pop phase (0% -> 35% of cycle)
          final progress = t / 0.35;
          final curveVal = Curves.easeOutCubic.transform(progress);
          dy = -4.5 * curveVal;
          scale = 1.0 + 0.04 * curveVal;
        } else if (t <= 0.65) {
          // Spring return phase (35% -> 65% of cycle)
          final progress = (t - 0.35) / 0.30;
          final curveVal = Curves.bounceOut.transform(progress);
          dy = -4.5 * (1.0 - curveVal);
          scale = 1.04 - 0.04 * Curves.easeInOutCubic.transform(progress);
        } else {
          // Calm resting pause phase (65% -> 100% of cycle)
          dy = 0.0;
          scale = 1.0;
        }

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            child: widget.child,
          ),
        );
      },
    );
  }
}
