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

enum ParticleShape { circle, rectangle, star, diamond }

/// One confetti particle with 2-phase physics:
/// Phase 1: Upward launch from left/right edge toward top center collision zone.
/// Phase 2: Mid-air impact collision, elastic rebound bounce, and gravitational downward fall.
@visibleForTesting
class ConfettiParticle {
  const ConfettiParticle({
    required this.origin,
    required this.targetCollision,
    required this.collisionTime,
    required this.preVelocity,
    required this.postVelocity,
    required this.color,
    required this.size,
    required this.spin,
    required this.shape,
    required this.fromLeft,
  });

  final Offset origin;
  final Offset targetCollision;
  final double collisionTime;
  final Offset preVelocity;
  final Offset postVelocity;
  final Color color;
  final double size;
  final double spin;
  final ParticleShape shape;
  final bool fromLeft;

  /// Calculates normalised position (0..1) at time progress [t]
  Offset positionAt(double t) {
    if (t <= collisionTime) {
      // Phase 1: Upward motion from left/right edge toward top collision zone
      final normT = (t / collisionTime).clamp(0.0, 1.0);
      final easeT = Curves.decelerate.transform(normT);
      final dx = origin.dx + (targetCollision.dx - origin.dx) * easeT;
      final dy = origin.dy + (targetCollision.dy - origin.dy) * easeT;
      return Offset(dx, dy);
    } else {
      // Phase 2: Post-collision rebound bounce and gravitational downward fall
      final dt = t - collisionTime;
      final dx = targetCollision.dx + postVelocity.dx * dt * (1.0 - 0.35 * dt);
      final dy = targetCollision.dy + postVelocity.dy * dt + 1.65 * dt * dt * 0.5;
      return Offset(dx, dy);
    }
  }

  /// Calculates rotation angle at time progress [t]
  double rotationAt(double t) {
    if (t <= collisionTime) {
      return spin * t;
    } else {
      final dt = t - collisionTime;
      return spin * collisionTime + (spin * 2.2) * dt;
    }
  }

  static const _palette = [
    Color(0xFFFFD700), // Gold
    Color(0xFFFF2A6D), // Electric Crimson
    Color(0xFF00F5D4), // Bright Turquoise
    Color(0xFFFF6B00), // Neon Orange
    Color(0xFFFF007F), // Vivid Magenta
    Color(0xFF7B2CBF), // Deep Purple
    Color(0xFF10B981), // Emerald Green
    Color(0xFF00B4D8), // Sky Blue
  ];

  /// Generate streams from left & right screen edges that shoot upward and collide at top area.
  static List<ConfettiParticle> burst({required int count, required int seed}) {
    final rand = math.Random(seed);
    return List.generate(count, (i) {
      final fromLeft = i.isEven;

      // 1. Origin: Starts at lower-left or lower-right screen edge
      final originX = fromLeft
          ? (0.01 + rand.nextDouble() * 0.08)
          : (0.91 + rand.nextDouble() * 0.08);
      final originY = 0.72 + rand.nextDouble() * 0.16;

      // 2. Collision Target: High top center area near top edge (y ~ 0.08 .. 0.22)
      final targetX = 0.35 + rand.nextDouble() * 0.30;
      final targetY = 0.08 + rand.nextDouble() * 0.14;

      // 3. Collision Time: Moment of collision (t_c ~ 0.34 .. 0.42)
      final collisionTime = 0.34 + rand.nextDouble() * 0.08;

      // 4. Pre-collision velocity
      final preVx = (targetX - originX) / collisionTime;
      final preVy = (targetY - originY) / collisionTime;

      // 5. Post-collision rebound velocity (bounce outward & upward impulse)
      final bounceDirection = fromLeft ? -1.0 : 1.0;
      final postVx = (bounceDirection * (0.35 + rand.nextDouble() * 0.45)) +
          (rand.nextDouble() - 0.5) * 0.3;
      final postVy = -0.25 - rand.nextDouble() * 0.30;

      final shapeTypes = ParticleShape.values;
      final shape = shapeTypes[rand.nextInt(shapeTypes.length)];

      return ConfettiParticle(
        origin: Offset(originX, originY),
        targetCollision: Offset(targetX, targetY),
        collisionTime: collisionTime,
        preVelocity: Offset(preVx, preVy),
        postVelocity: Offset(postVx, postVy),
        color: _palette[rand.nextInt(_palette.length)],
        size: 6.0 + rand.nextDouble() * 8.0,
        spin: (rand.nextDouble() - 0.5) * 14,
        shape: shape,
        fromLeft: fromLeft,
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
    final fade = progress < 0.70 ? 1.0 : (1.0 - (progress - 0.70) / 0.30);

    // 1. Render Top Center Collision Shockwave Impact Ring
    if (progress >= 0.30 && progress <= 0.58) {
      final ringT = ((progress - 0.30) / 0.28).clamp(0.0, 1.0);
      final ringRadius = 15.0 + ringT * 90.0;
      final ringAlpha = (1.0 - ringT).clamp(0.0, 1.0) * 0.65;

      final shockwavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * (1.0 - ringT)
        ..color = const Color(0xFFFFD700).withValues(alpha: ringAlpha);

      canvas.drawCircle(
        Offset(size.width * 0.50, size.height * 0.14),
        ringRadius,
        shockwavePaint,
      );
    }

    // 2. Render Confetti Particles with physics trajectory
    for (final p in particles) {
      final at = p.positionAt(progress);
      final centre = Offset(at.dx * size.width, at.dy * size.height);
      if (centre.dy > size.height + 40) continue;

      paint.color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(p.rotationAt(progress));

      switch (p.shape) {
        case ParticleShape.circle:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;

        case ParticleShape.rectangle:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.55,
            ),
            paint,
          );
          break;

        case ParticleShape.star:
          canvas.drawPath(_createStarPath(p.size), paint);
          break;

        case ParticleShape.diamond:
          canvas.drawPath(_createDiamondPath(p.size), paint);
          break;
      }

      canvas.restore();
    }
  }

  Path _createStarPath(double size) {
    final path = Path();
    final r = size / 2;
    final innerR = r * 0.45;
    for (int i = 0; i < 8; i++) {
      final radius = i.isEven ? r : innerR;
      final angle = i * math.pi / 4;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _createDiamondPath(double size) {
    final path = Path();
    final w = size * 0.65;
    final h = size;
    path.moveTo(0, -h / 2);
    path.lineTo(w / 2, 0);
    path.lineTo(0, h / 2);
    path.lineTo(-w / 2, 0);
    path.close();
    return path;
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
