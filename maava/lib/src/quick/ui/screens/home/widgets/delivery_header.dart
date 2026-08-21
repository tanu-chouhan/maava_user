import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../domain/model/category.dart';
import '../../../../di/app_providers.dart';
import '../../../../navigation/route_paths.dart';
import '../../../common/smart_scan.dart';
import '../../../common/widgets/inputs/search_bar_widget.dart';
import '../../notifications/notifications_provider.dart';

/// Mart's Header section, matching the screenshot spec:
///
/// - Warm Vibrant Orange Gradient background spanning status bar down to tabs.
/// - Top Row:
///   - Subtitle: "MAAVA Quick Commerce"
///   - Large Bold ETA: "14 minutes"
///   - Selected location & address line with dropdown caret `v`
///   - Top Right: Circular badge with pass/wallet/notification icon.
/// - Search Bar Row:
///   - Full-width white capsule container with Search icon, "Search 'dal'" hint, and filter icon.
/// - Category Navigation Bar:
///   - Horizontal scrollable strip of icon categories (All, Wedding, Winter, Electronics, Beauty, Grocery, Fashion...)
///   - "All" tab features the active black pill indicator line underneath.
class DeliveryHeader extends ConsumerStatefulWidget {
  const DeliveryHeader({
    super.key,
    this.categories = const [],
    this.onCategoryTap,
    this.onAllTap,
  });

  final List<Category> categories;
  final ValueChanged<String>? onCategoryTap;
  final VoidCallback? onAllTap;

  @override
  ConsumerState<DeliveryHeader> createState() => _DeliveryHeaderState();
}

class _DeliveryHeaderState extends ConsumerState<DeliveryHeader> {
  String _selectedCategoryId = 'all';

  @override
  Widget build(BuildContext context) {
    final address = ref.watch(selectedAddressProvider);
    final unread = ref.watch(notificationsProvider.select((s) => s.unreadCount));
    final topPadding = MediaQuery.of(context).padding.top;

    final String addressLine;
    if (address != null && address.shortLine.trim().isNotEmpty) {
      final label = address.label.wireValue.trim();
      final short = address.shortLine.trim();
      addressLine = label.isNotEmpty ? '$label - $short' : short;
    } else {
      addressLine = 'Appzeto, Princess Center, New Palasia, Indore, Madhya Pradesh';
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFA751C), // Vibrant warm orange
            Color(0xFFFB8C2E), // Rich orange
            Color(0xFFFF9736), // Soft orange bottom
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topPadding + 6),

          // 1. TOP LOCATION & ETA ROW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MAAVA Quick Commerce',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF232323),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '14 minutes',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          letterSpacing: -0.5,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 3),
                      GestureDetector(
                        onTap: () => context.push(RoutePaths.addresses),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                addressLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2D2D2D),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Color(0xFF2D2D2D),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Right side circular action badge (Pass / Wallet / Profile)
                GestureDetector(
                  onTap: () => context.push(RoutePaths.notifications),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.subtitles_outlined,
                          size: 22,
                          color: Color(0xFF1E1E1E),
                        ),
                        if (unread > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. SEARCH BAR ROW (Original SearchBarWidget with animated hints, mic & barcode scanner)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBarWidget(
              readOnly: true,
              categories: widget.categories.map((c) => c.name).toList(),
              onTap: () => context.push(RoutePaths.search),
              onScanTap: () => SmartScan.run(context, ref),
              onMicTap: () => context.push('${RoutePaths.search}?voice=1'),
            ),
          ),

          const SizedBox(height: 14),

          // 3. HORIZONTAL CATEGORY NAVIGATION STRIP
          _buildCategoryTabsRow(context),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildCategoryTabsRow(BuildContext context) {
    // Preset icons matching the screenshot spec exactly
    final List<_CategoryTabItem> defaultItems = [
      const _CategoryTabItem(id: 'all', label: 'All', icon: Icons.home_outlined),
      const _CategoryTabItem(id: 'wedding', label: 'Wedding', icon: Icons.calendar_month_outlined),
      const _CategoryTabItem(id: 'winter', label: 'Winter', icon: Icons.wb_sunny_outlined),
      const _CategoryTabItem(id: 'electronics', label: 'Electronics', icon: Icons.tv_rounded),
      const _CategoryTabItem(id: 'beauty', label: 'Beauty', icon: Icons.local_mall_outlined),
      const _CategoryTabItem(id: 'grocery', label: 'Grocery', icon: Icons.shopping_cart_outlined),
      const _CategoryTabItem(id: 'fashion', label: 'Fashion', icon: Icons.checkroom_rounded),
    ];

    // Combine preset items with any extra categories loaded from backend
    final Map<String, _CategoryTabItem> combinedMap = {};
    for (final item in defaultItems) {
      combinedMap[item.id] = item;
    }
    for (final cat in widget.categories) {
      final key = cat.id.toLowerCase();
      if (!combinedMap.containsKey(key)) {
        combinedMap[key] = _CategoryTabItem(
          id: cat.id,
          label: cat.name,
          icon: _iconForCategoryName(cat.name),
          imageUrl: cat.imageUrl,
        );
      }
    }

    final items = combinedMap.values.toList();

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = _selectedCategoryId == item.id;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategoryId = item.id);
              if (item.id == 'all') {
                widget.onAllTap?.call();
              } else {
                widget.onCategoryTap?.call(item.id);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item.id == 'all'
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: item.id == 'all'
                        ? Border.all(
                            color: const Color(0xFF1E1E1E),
                            width: 1.5,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    item.icon,
                    size: 24,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: const Color(0xFF111111),
                  ),
                ),
                if (isSelected && item.id == 'all') ...[
                  const SizedBox(height: 3),
                  Container(
                    width: 26,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _iconForCategoryName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('grocery') || lower.contains('food')) return Icons.shopping_cart_outlined;
    if (lower.contains('beauty') || lower.contains('care')) return Icons.local_mall_outlined;
    if (lower.contains('electronic') || lower.contains('tech')) return Icons.tv_rounded;
    if (lower.contains('fashion') || lower.contains('cloth')) return Icons.checkroom_rounded;
    if (lower.contains('winter')) return Icons.wb_sunny_outlined;
    if (lower.contains('wedding')) return Icons.calendar_month_outlined;
    return Icons.category_rounded;
  }
}

class _CategoryTabItem {
  const _CategoryTabItem({
    required this.id,
    required this.label,
    required this.icon,
    this.imageUrl = '',
  });

  final String id;
  final String label;
  final IconData icon;
  final String imageUrl;
}
