import '../../../../../presentation/orders/widgets/celebration_painter.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/haptics.dart';
import '../../../../../presentation/branding/app_colors.dart';
import '../../../../../shared/ui/food_style_card.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../domain/model/order.dart';
import '../../../../navigation/route_paths.dart';
import '../../../common/widgets/buttons/primary_button.dart';
import '../../../common/widgets/buttons/secondary_button.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final Order order;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Haptics.medium();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) Haptics.success();
      });
      _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Animation<double> _getInterval(double start, double end) {
    return CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(RoutePaths.home);
      },
      child: CelebrationEffect(
        child: Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _staggerController,
                      builder: (context, _) => CustomPaint(
                        painter: _ConfettiPainter(
                          progress: _staggerController.value,
                          colors: const [
                            Color(0xFFFF5252),
                            Color(0xFFFFD56F),
                            Color(0xFF10B981),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _CheckMorph(controller: _staggerController),
                      const SizedBox(height: 28),
                      _StaggeredWidget(
                        animation: _getInterval(0.1, 0.4),
                        child: Text(
                          'Order placed!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StaggeredWidget(
                        animation: _getInterval(0.2, 0.5),
                        child: Text(
                          order.etaMinutes != null
                              ? 'Arriving in about ${order.etaMinutes} minutes'
                              : 'We are packing your items right now',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _StaggeredWidget(
                        animation: _getInterval(0.3, 0.6),
                        child: FoodStyleCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Order Summary',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _Row(label: 'Order ID', value: order.displayId),
                              const SizedBox(height: 10),
                              _Row(label: 'Items', value: '${order.itemCount} items'),
                              const SizedBox(height: 10),
                              _Row(label: 'Paid via', value: order.paymentMethod.label),
                              const SizedBox(height: 12),
                              Divider(color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9)),
                              const SizedBox(height: 12),
                              _Row(
                                label: 'Total Paid',
                                value: order.pricing.total.asCurrency,
                                emphasise: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (order.lines.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _StaggeredWidget(
                          animation: _getInterval(0.4, 0.7),
                          child: FoodStyleCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Items in Order',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                for (final item in order.lines) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${item.quantity}x',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          item.lineTotal.asCurrency,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _StaggeredWidget(
                        animation: _getInterval(0.5, 0.8),
                        child: PrimaryButton(
                          label: 'Track your order',
                          icon: Icons.delivery_dining_rounded,
                          onPressed: () => context.go(RoutePaths.orderTrackingOf(order.id)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StaggeredWidget(
                        animation: _getInterval(0.6, 0.9),
                        child: SecondaryButton(
                          label: 'Continue shopping',
                          expand: true,
                          onPressed: () => context.go(RoutePaths.home),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaggeredWidget extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const _StaggeredWidget({
    required this.child,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final opacity = animation.value.clamp(0.0, 1.0);
        final translateY = (1.0 - opacity) * 30;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasise ? 17 : 14,
            fontWeight: emphasise ? FontWeight.w900 : FontWeight.w600,
            color: emphasise ? AppColors.primary : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}

/// Circle that draws itself, then a tick that strokes in.
class _CheckMorph extends StatelessWidget {
  const _CheckMorph({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      width: 110,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final ring = Curves.easeOutCubic.transform(
            (controller.value / 0.45).clamp(0.0, 1.0),
          );
          final tick = Curves.easeOutBack.transform(
            ((controller.value - 0.35) / 0.4).clamp(0.0, 1.0),
          );

          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 110,
                width: 110,
                child: CircularProgressIndicator(
                  value: ring,
                  strokeWidth: 4,
                  color: const Color(0xFF10B981),
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                ),
              ),
              Transform.scale(
                scale: tick,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Deterministic confetti.
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  static const _count = 42;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;

    for (var i = 0; i < _count; i++) {
      final seed = i / _count;
      final x = size.width * ((seed * 7.3) % 1);
      final drift = math.sin((progress + seed) * math.pi * 2) * 22;
      final y = -20 + (size.height + 60) * ((progress * 1.35) - seed * 0.3);
      if (y < -20 || y > size.height) continue;

      final paint = Paint()
        ..color = colors[i % colors.length]
            .withValues(alpha: (1 - progress).clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(x + drift, y);
      canvas.rotate((progress * 6 + seed * 3) % (math.pi * 2));
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 11),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
