import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/utils/haptics.dart';
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

  @override
  void initState() {
    super.initState();
    Haptics.success();
  }

  late final List<ConfettiParticle> _particles = ConfettiParticle.burst(
    count: 75,
    seed: widget.code.hashCode,
  );

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saved = '₹${widget.savings % 1 == 0 ? widget.savings.toStringAsFixed(0) : widget.savings.toStringAsFixed(2)}';

    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti sits behind and around the card, and ignores pointers
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
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _confetti,
                  curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  elevation: 12,
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
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
                            size: 32,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'You saved $saved',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            color: Color(0xFF16211A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.code.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Coupon applied to your order 🎉',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7A70),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Haptics.light();
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
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

  /// Gravity in normalised units, tuned so chips float high up into top screen area.
  static const _gravity = 0.65;

  static const _palette = [
    Color(0xFFFFC107),
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFF7C5CFF),
    Color(0xFF2ECC71),
    Color(0xFFFF8A3D),
    Color(0xFF3498DB),
    Color(0xFFE91E63),
  ];

  /// Upward fans and top-floating confetti particles that cover the top of screen.
  static List<ConfettiParticle> burst({required int count, required int seed}) {
    final rand = math.Random(seed);
    return List.generate(count, (i) {
      if (i < count * 0.75) {
        // Upward cannons from left/right lower-mid screen extending high to top
        final fromLeft = i.isEven;
        final angle = (fromLeft ? 1.0 : -1.0) *
            (math.pi / 8 + rand.nextDouble() * math.pi / 3);
        final speed = 0.85 + rand.nextDouble() * 0.70;
        return ConfettiParticle(
          origin: Offset(fromLeft ? 0.05 : 0.95, 0.60),
          velocity: Offset(math.sin(angle) * speed, -math.cos(angle) * speed),
          color: _palette[rand.nextInt(_palette.length)],
          size: 6 + rand.nextDouble() * 7,
          spin: (rand.nextDouble() - 0.5) * 12,
          round: rand.nextBool(),
        );
      } else {
        // High top-screen cascade floating down
        return ConfettiParticle(
          origin: Offset(
            0.05 + rand.nextDouble() * 0.90,
            -0.05 + rand.nextDouble() * 0.35,
          ),
          velocity: Offset(
            (rand.nextDouble() - 0.5) * 0.5,
            0.15 + rand.nextDouble() * 0.45,
          ),
          color: _palette[rand.nextInt(_palette.length)],
          size: 5 + rand.nextDouble() * 7,
          spin: (rand.nextDouble() - 0.5) * 10,
          round: rand.nextBool(),
        );
      }
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
