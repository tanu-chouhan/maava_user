import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';

/// "Featured this week" horizontal rail section matching the reference design 1:1:
///
/// - Title: "Featured this week" in bold headline typography.
/// - Card 1: NEWLY LAUNCHED (Warm gold gradient, red banner, white product box, "For You" bottom badge).
/// - Card 2: PRICE DROP (Deep royal blue gradient, red "Featured" badge, 3D golden "PRICE DROP" text).
/// - Card 3: Plum Cakes / Festive Special (Deep ruby crimson striped background, "Plum Cakes" title, cake graphic).
class FeaturedThisWeekRow extends StatelessWidget {
  const FeaturedThisWeekRow({
    super.key,
    this.onCardTap,
  });

  final ValueChanged<int>? onCardTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECTION TITLE: "Featured this week"
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Text(
              'Featured this week',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.3,
                color: const Color(0xFF111827),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // HORIZONTAL CAROUSEL RAIL
          SizedBox(
            height: 210,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              children: [
                // CARD 1: NEWLY LAUNCHED
                GestureDetector(
                  onTap: () => onCardTap?.call(0),
                  child: _buildNewlyLaunchedCard(),
                ),

                const SizedBox(width: 12),

                // CARD 2: PRICE DROP
                GestureDetector(
                  onTap: () => onCardTap?.call(1),
                  child: _buildPriceDropCard(),
                ),

                const SizedBox(width: 12),

                // CARD 3: PLUM CAKES
                GestureDetector(
                  onTap: () => onCardTap?.call(2),
                  child: _buildPlumCakesCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewlyLaunchedCard() {
    return Container(
      width: 144,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Top Red Header Banner Badge ("NEWLY LAUNCHED")
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFF97316)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'NEWLY\nLAUNCHED',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Center White Product Box Container
          Container(
            width: 104,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Image.network(
              'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=200',
              width: 80,
              height: 65,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.star_rounded,
                size: 36,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),

          const Spacer(),

          // Bottom Pill Badge ("For You")
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF78350F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'For You •',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDropCard() {
    return Container(
      width: 144,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF60A5FA), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Top Red Header Banner Badge ("Featured")
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Featured',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),

          const Spacer(),

          // Main 3D Text ("PRICE DROP")
          Text(
            'PRICE',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFBBF24),
              height: 1.0,
              letterSpacing: 1.2,
              shadows: const [
                Shadow(offset: Offset(0, 2), blurRadius: 0, color: Color(0x99000000)),
                Shadow(offset: Offset(0, 4), blurRadius: 4, color: Color(0x4D000000)),
              ],
            ),
          ),
          Text(
            'DROP',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFF87171),
              height: 1.0,
              letterSpacing: 1.2,
              shadows: const [
                Shadow(offset: Offset(0, 2), blurRadius: 0, color: Color(0x99000000)),
                Shadow(offset: Offset(0, 4), blurRadius: 4, color: Color(0x4D000000)),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPlumCakesCard() {
    return Container(
      width: 144,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF881337), Color(0xFF9F1239), Color(0xFFBE123C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFB7185), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Top Red Header Banner Badge ("Featured")
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Featured',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Subtitle Title ("Plum Cakes")
          Text(
            'Plum Cakes',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),

          const Spacer(),

          // Festive Cake Illustration Graphic 🎂
          Container(
            height: 80,
            alignment: Alignment.center,
            child: const Text(
              '🎂',
              style: TextStyle(fontSize: 54),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}
