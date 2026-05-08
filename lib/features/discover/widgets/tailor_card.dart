import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:khayyat/features/discover/view_model/discover_provider.dart';
import 'package:khayyat/utils/app_colors.dart';

class TailorCard extends StatelessWidget {
  final DiscoverShop discoverShop;
  final VoidCallback onTap;

  const TailorCard({
    super.key,
    required this.discoverShop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shop = discoverShop.shop;
    final dist = discoverShop.distanceKm;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover photo ──────────────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: _CoverPhoto(url: shop.coverPhotoUrl, height: 110),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name row ──────────────────────────────────────────
                  Row(
                    children: [
                      _LogoCircle(url: shop.logoUrl, name: shop.name),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          shop.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (shop.isVerified) _VerifiedBadge(),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ── Location ──────────────────────────────────────────
                  if (shop.city.isNotEmpty || shop.area.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.gray),
                        const SizedBox(width: 3),
                        Text(
                          [shop.area, shop.city]
                              .where((s) => s.isNotEmpty)
                              .join(', '),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.gray),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),

                  // ── Rating + distance row ─────────────────────────────
                  Row(
                    children: [
                      if (shop.totalRatings > 0) ...[
                        const Icon(Icons.star_rounded,
                            size: 15, color: Color(0xFFF39C12)),
                        const SizedBox(width: 3),
                        Text(
                          shop.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                        Text(
                          '  (${shop.totalRatings})',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.gray),
                        ),
                      ] else
                        const Text('No reviews yet',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.gray)),
                      const Spacer(),
                      if (dist != null)
                        Row(
                          children: [
                            const Icon(Icons.near_me_outlined,
                                size: 13, color: AppColors.navy),
                            const SizedBox(width: 3),
                            Text(
                              dist < 1
                                  ? '${(dist * 1000).toStringAsFixed(0)} m'
                                  : '${dist.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Specialities chips ────────────────────────────────
                  if (shop.specialities.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: shop.specialities.take(3).map((s) {
                        return _SpecialityChip(label: s);
                      }).toList(),
                    ),

                  // ── Working hours ─────────────────────────────────────
                  if (shop.workingHours.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: AppColors.gray),
                        const SizedBox(width: 4),
                        Text(
                          shop.workingHours,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.gray),
                        ),
                        if (shop.workingDays.isNotEmpty) ...[
                          const Text('  ·  ',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.gray)),
                          Text(
                            shop.workingDays,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.gray),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CoverPhoto extends StatelessWidget {
  final String? url;
  final double height;

  const _CoverPhoto({this.url, required this.height});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => _placeholder(height),
        errorWidget: (context, url, error) => _placeholder(height),
      );
    }
    return _placeholder(height);
  }

  Widget _placeholder(double h) {
    return Container(
      height: h,
      width: double.infinity,
      color: AppColors.navy.withValues(alpha: 0.08),
      child: const Icon(Icons.content_cut,
          color: AppColors.navy, size: 32),
    );
  }
}

class _LogoCircle extends StatelessWidget {
  final String? url;
  final String name;

  const _LogoCircle({this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.navy,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => _initials(),
            )
          : _initials(),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 11, color: AppColors.green),
          SizedBox(width: 3),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialityChip extends StatelessWidget {
  final String label;

  const _SpecialityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
      ),
    );
  }
}
