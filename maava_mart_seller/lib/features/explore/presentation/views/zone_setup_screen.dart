import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maava_mart_seller/config/theme/app_colors.dart';
import 'package:maava_mart_seller/config/theme/app_text_styles.dart';
import 'package:maava_mart_seller/core/widgets/app_toast.dart';
import 'package:maava_mart_seller/config/theme/app_palette.dart';

class ZoneSetupScreen extends StatelessWidget {
  const ZoneSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        backgroundColor: context.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.textPrimary,
            size: 18,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Zone Setup',
          style: AppTextStyles.h3.copyWith(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Map Preview Box with Polygon Graphic
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: Stack(
                  children: [
                    // Grid background simulating map
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _MapGridPainter(),
                      ),
                    ),
                    // Polygon Overlay
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryDark,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.location_on_rounded,
                            color: context.textPrimary,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Zone Details Card & Add Zone
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zone 1 (Default)',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: context.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Radius: 5 km',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => AppToast.show(
                            context,
                            'Zone editing needs the map backend',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF181C2E),
                            side: BorderSide(color: context.textPrimary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(90, 38),
                          ),
                          child: const Text(
                            'Edit Zone',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => AppToast.show(
                      context,
                      'Zone creation needs the map backend',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF181C2E),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: context.textPrimary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Add New Zone',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.button.copyWith(
                              color: context.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB).withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
