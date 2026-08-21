import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_theme.dart';

/// One row of the Food/Mart split.
class VerticalBreakdownRow {
  const VerticalBreakdownRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;

  /// Pre-formatted, because the same sheet shows rupees in one place and a
  /// plain count in the other.
  final String value;

  final IconData icon;
  final Color tint;
}

/// Bottom sheet that breaks a headline number into its Maava Food and Maava
/// Mart parts, with the combined total below the divider.
///
/// One widget for both the earnings and the orders card: they differ only in
/// their labels and formatting, and having two near-identical sheets is how
/// they drift apart.
///
/// The total is passed in already computed by the caller from the same source
/// as the rows — it is never re-derived here, so the sheet cannot show a total
/// that disagrees with the parts it is displaying.
class VerticalBreakdownSheet extends StatelessWidget {
  const VerticalBreakdownSheet({
    super.key,
    required this.title,
    required this.rows,
    required this.totalLabel,
    required this.totalValue,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<VerticalBreakdownRow> rows;
  final String totalLabel;
  final String totalValue;

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<VerticalBreakdownRow> rows,
    required String totalLabel,
    required String totalValue,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      // Long labels and large text settings must not clip the total, which is
      // the whole point of the sheet.
      isScrollControlled: true,
      builder: (_) => VerticalBreakdownSheet(
        title: title,
        subtitle: subtitle,
        rows: rows,
        totalLabel: totalLabel,
        totalValue: totalValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.darkCard : Colors.white;
    final onSurface = isDark ? Colors.white : Colors.black87;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: onSurface,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 2.h),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
            ],
            SizedBox(height: 16.h),
            for (final row in rows) ...[
              _Row(row: row, onSurface: onSurface),
              SizedBox(height: 10.h),
            ],
            Divider(height: 20.h, color: Colors.grey.withValues(alpha: 0.25)),
            Row(
              children: [
                Expanded(
                  child: Text(
                    totalLabel,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                    ),
                  ),
                ),
                Text(
                  totalValue,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.onSurface});

  final VerticalBreakdownRow row;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(7.r),
          decoration: BoxDecoration(
            color: row.tint.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(row.icon, size: 16.sp, color: row.tint),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            row.label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
        ),
        Text(
          row.value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
      ],
    );
  }
}
