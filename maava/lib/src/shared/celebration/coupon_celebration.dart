import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../presentation/branding/app_colors.dart';

/// The coupon-applied celebration, shared by both verticals.
///
/// Shown only once the server has actually accepted the coupon — the caller
/// passes the code and saving it echoed back, so nothing here is invented.
///
/// The confetti runs once and settles; the card stays until dismissed, which is
/// what leaves the user back on the cart/checkout they came from.
Future<void> showCouponCelebration(
  BuildContext context, {
  required String code,
  required double savings,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _CouponCelebration(code: code, savings: savings),
  );
}

class _CouponCelebration extends StatefulWidget {
  const _CouponCelebration({required this.code, required this.savings});

  final String code;
  final double savings;

  @override
  State<_CouponCelebration> createState() => _CouponCelebrationState();
}

class _CouponCelebrationState extends State<_CouponCelebration>
    with SingleTickerProviderStateMixin {
  static const _burst = Duration(milliseconds: 2600);

  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: _burst,
  )..forward();

  late final List<ConfettiParticle> _particles = ConfettiParticle.burst(
    count: 44,
    seed: widget.code.hashCode,
  );

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saved = '₹${widget.savings.toStringAsFixed(0)}';

    // Expanded deliberately: a dialog hands its child *loose* constraints, so a
    // bare Stack shrink-wraps to the card and `Positioned.fill` then covers only
    // the card — the confetti painted behind it and was never visible.
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti sits behind and around the card, and ignores pointers so it
          // never swallows a tap meant for the dialog.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (context, _) => CustomPaint(
                  painter: ConfettiPainter(
                    particles: _particles,
                    progress: _confetti.value,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.local_offer_rounded,
                          size: 30,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'You saved $saved',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: Color(0xFF16211A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.code.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Coupon applied to your order 🎉',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Color(0xFF6B7A70),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One confetti chip: where it starts, where it drifts, and how it tumbles.
@visibleForTesting
class ConfettiParticle {
  const ConfettiParticle({
    required this.origin,
    required this.velocity,
    required this.color,
    required this.size,
    required this.spin,
    required this.round,
  });

  final Offset origin;
  final Offset velocity;
  final Color color;
  final double size;
  final double spin;
  final bool round;

  /// Normalised centre at [t] (0..1): the launch vector plus gravity. Exposed
  /// so a test can prove chips are actually on screen mid-burst — a burst that
  /// flies off instantly looks identical to one that never rendered.
  Offset positionAt(double t) => Offset(
        origin.dx + velocity.dx * t,
        origin.dy + velocity.dy * t + _gravity * t * t * 0.5,
      );

  /// Gravity in normalised units, tuned so chips arc over rather than fly off.
  static const _gravity = 1.15;

  static const _palette = [
    Color(0xFFFFC107),
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFF7C5CFF),
    Color(0xFF2ECC71),
    Color(0xFFFF8A3D),
  ];

  /// Two upward fans from the lower corners, the way a party popper throws.
  static List<ConfettiParticle> burst({required int count, required int seed}) {
    final rand = math.Random(seed);
    return List.generate(count, (i) {
      final fromLeft = i.isEven;
      // Fan *inward*: a chip launched from the left corner has to travel right
      // to cross the card. With these signs mirrored every chip flew straight
      // off its own side of the screen, so the burst was never visible.
      final angle =
          (fromLeft ? 1.0 : -1.0) *
          (math.pi / 5 + rand.nextDouble() * math.pi / 3);
      final speed = 0.55 + rand.nextDouble() * 0.55;
      return ConfettiParticle(
        origin: Offset(fromLeft ? 0.06 : 0.94, 0.78),
        velocity: Offset(math.sin(angle) * speed, -math.cos(angle) * speed),
        color: _palette[rand.nextInt(_palette.length)],
        size: 5 + rand.nextDouble() * 7,
        spin: (rand.nextDouble() - 0.5) * 10,
        round: rand.nextBool(),
      );
    });
  }
}

@visibleForTesting
class ConfettiPainter extends CustomPainter {
  const ConfettiPainter({required this.particles, required this.progress});

  final List<ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final paint = Paint();
    // Fade out over the last third so the burst settles instead of vanishing.
    final fade = progress < 0.66 ? 1.0 : (1 - (progress - 0.66) / 0.34);

    for (final p in particles) {
      final at = p.positionAt(progress);
      final centre = Offset(at.dx * size.width, at.dy * size.height);
      if (centre.dy > size.height + 40) continue;

      paint.color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(p.spin * progress);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.55,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) => old.progress != progress;
}

/// What a coupon screen hands back to the cart that opened it, so the cart can
/// celebrate on its own context once the picker has closed.
class CouponWin {
  const CouponWin({required this.code, required this.savings});

  final String code;
  final double savings;
}
