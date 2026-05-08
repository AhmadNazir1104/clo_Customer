import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:khayyat/features/discover/view_model/discover_provider.dart';
import 'package:khayyat/model/review_model.dart';
import 'package:khayyat/model/shop_model.dart';
import 'package:khayyat/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class TailorDetailScreen extends ConsumerWidget {
  final ShopModel shop;

  const TailorDetailScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(shopReviewsProvider(shop.shopId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Sticky cover photo app bar ──────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.navy,
            leading: _BackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: _CoverPhoto(url: shop.coverPhotoUrl),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Shop identity card ────────────────────────────────
                _InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LogoCircle(url: shop.logoUrl, name: shop.name),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        shop.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.dark,
                                        ),
                                      ),
                                    ),
                                    if (shop.isVerified) ...[
                                      const SizedBox(width: 8),
                                      _VerifiedBadge(),
                                    ],
                                  ],
                                ),
                                if (shop.city.isNotEmpty ||
                                    shop.area.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined,
                                          size: 14, color: AppColors.gray),
                                      const SizedBox(width: 4),
                                      Text(
                                        [shop.area, shop.city]
                                            .where((s) => s.isNotEmpty)
                                            .join(', '),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.gray),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 6),
                                _RatingRow(
                                    rating: shop.rating,
                                    total: shop.totalRatings),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Specialities ──────────────────────────────────────
                if (shop.specialities.isNotEmpty)
                  _InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Specialities'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: shop.specialities.map((s) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.navy.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                s,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                if (shop.specialities.isNotEmpty) const SizedBox(height: 12),

                // ── Working hours ─────────────────────────────────────
                if (shop.workingHours.isNotEmpty ||
                    shop.workingDays.isNotEmpty)
                  _InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Working Hours'),
                        const SizedBox(height: 10),
                        if (shop.workingHours.isNotEmpty)
                          _DetailRow(
                            icon: Icons.access_time_rounded,
                            label: shop.workingHours,
                          ),
                        if (shop.workingDays.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _DetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: shop.workingDays,
                          ),
                        ],
                      ],
                    ),
                  ),

                if (shop.workingHours.isNotEmpty ||
                    shop.workingDays.isNotEmpty)
                  const SizedBox(height: 12),

                // ── Description ───────────────────────────────────────
                if (shop.description != null &&
                    shop.description!.isNotEmpty)
                  _InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('About'),
                        const SizedBox(height: 8),
                        Text(
                          shop.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.dark,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (shop.description != null && shop.description!.isNotEmpty)
                  const SizedBox(height: 12),

                // ── WhatsApp button ───────────────────────────────────
                if (shop.whatsappNumber != null &&
                    shop.whatsappNumber!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _openWhatsApp(shop.whatsappNumber!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.chat, size: 20),
                        label: const Text(
                          'Chat on WhatsApp',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),

                if (shop.whatsappNumber != null &&
                    shop.whatsappNumber!.isNotEmpty)
                  const SizedBox(height: 12),

                // ── Leave Review button ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/review/${shop.shopId}',
                        extra: shop.name,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.navy, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        foregroundColor: AppColors.navy,
                      ),
                      icon: const Icon(Icons.star_border_rounded, size: 20),
                      label: const Text(
                        'Leave a Review',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Reviews section ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      if (shop.totalRatings > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${shop.totalRatings})',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.gray),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                reviews.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.navy),
                    ),
                  ),
                  error: (context, url) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Could not load reviews.',
                        style: TextStyle(color: AppColors.gray)),
                  ),
                  data: (list) => list.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
                          child: Text(
                            'No reviews yet. Be the first!',
                            style:
                                TextStyle(fontSize: 13, color: AppColors.gray),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: list.length,
                          separatorBuilder: (context, url) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _ReviewCard(review: list[i]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openWhatsApp(String number) async {
    final cleaned =
        number.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0'), '92');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.gray,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Back button overlay ───────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CircleAvatar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        radius: 18,
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 16, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
    );
  }
}

// ── Cover photo ───────────────────────────────────────────────────────────────

class _CoverPhoto extends StatelessWidget {
  final String? url;

  const _CoverPhoto({this.url});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => _placeholder(),
        errorWidget: (context, url, error) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.navy.withValues(alpha: 0.85),
      child: const Center(
        child: Icon(Icons.content_cut, size: 52, color: Colors.white54),
      ),
    );
  }
}

// ── Logo circle ───────────────────────────────────────────────────────────────

class _LogoCircle extends StatelessWidget {
  final String? url;
  final String name;

  const _LogoCircle({this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
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
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ── Rating row ────────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final double rating;
  final int total;

  const _RatingRow({required this.rating, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return const Text('No reviews yet',
          style: TextStyle(fontSize: 13, color: AppColors.gray));
    }
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < rating.floor()) {
            return const Icon(Icons.star_rounded,
                size: 16, color: Color(0xFFF39C12));
          } else if (i < rating) {
            return const Icon(Icons.star_half_rounded,
                size: 16, color: Color(0xFFF39C12));
          }
          return const Icon(Icons.star_border_rounded,
              size: 16, color: Color(0xFFF39C12));
        }),
        const SizedBox(width: 6),
        Text(
          '${rating.toStringAsFixed(1)}  ($total reviews)',
          style: const TextStyle(fontSize: 13, color: AppColors.gray),
        ),
      ],
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gray),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(fontSize: 14, color: AppColors.dark)),
      ],
    );
  }
}

// ── Info card container ───────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowLight, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}

// ── Verified badge ────────────────────────────────────────────────────────────

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 12, color: AppColors.green),
          SizedBox(width: 4),
          Text('Verified',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green)),
        ],
      ),
    );
  }
}

// ── Review card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowLight, blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.customerName,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color: const Color(0xFFF39C12),
                  ),
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment!,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.gray, height: 1.4),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            DateFormat('d MMM yyyy').format(review.createdAt),
            style:
                const TextStyle(fontSize: 11, color: AppColors.gray),
          ),
        ],
      ),
    );
  }
}
