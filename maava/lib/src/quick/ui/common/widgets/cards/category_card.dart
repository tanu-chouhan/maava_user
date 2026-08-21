import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/model/category.dart';
import '../misc/app_network_image.dart';

/// Category tile matching exact Blinkit-style reference screenshot:
/// Light mint pastel rounded squircle container (16px radius) + 2-line title.
class CategoryCard extends StatefulWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.size = 74,
    this.showCount = false,
  });

  final Category category;
  final VoidCallback onTap;
  final double size;
  final bool showCount;

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: AppDurations.instant,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // White Rounded Rectangular Card Container (Matching Reference Screenshot 1:1)
            Container(
              height: widget.size,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: AppNetworkImage(
                url: widget.category.imageUrl,
                height: widget.size - 16,
                width: double.infinity,
                fit: BoxFit.contain,
                fallbackIcon: Icons.shopping_basket_outlined,
              ),
            ),
            const SizedBox(height: 6),

            // 2-Line Bold Category Title
            Text(
              widget.category.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                color: const Color(0xFF111827),
                height: 1.15,
              ),
            ),

            if (widget.showCount && widget.category.itemCount > 0)
              Text(
                '${widget.category.itemCount} items',
                style: context.text.bodySmall!.copyWith(fontSize: 9.5),
              ),
          ],
        ),
      ),
    );
  }
}
