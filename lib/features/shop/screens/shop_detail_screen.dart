import 'package:khayyat/features/shop/view_model/shop_view_model.dart';
import 'package:khayyat/l10n/app_localizations.dart';
import 'package:khayyat/utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ShopDetailScreen extends ConsumerWidget {
  final String shopId;
  const ShopDetailScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n     = AppLocalizations.of(context)!;
    final shopAsync = ref.watch(shopProvider(shopId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.dark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.shopDetails,
          style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.dark),
        ),
      ),
      body: shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.gray)),
        ),
        data: (shop) {
          if (shop == null) {
            return const Center(
              child: Text('Shop not found.',
                  style: TextStyle(fontSize: 15, color: AppColors.gray)),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // ── Logo + name ─────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    _shopLogo(shop.logoUrl, shop.name),
                    const SizedBox(height: 16),
                    Text(
                      shop.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // ── Info card ────────────────────────────────────────────
              _card(
                child: Column(
                  children: [
                    _infoRow(Icons.location_on_outlined, 'Address', shop.address),
                    const Divider(height: 24),
                    _infoRow(Icons.phone_outlined, 'Phone', shop.phone),
                    if (shop.shopCode != null) ...[
                      const Divider(height: 24),
                      _infoRow(Icons.qr_code, 'Shop Code', shop.shopCode!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ── Call button ──────────────────────────────────────────
              if (shop.phone.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _copyPhone(context, shop.phone),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text(
                      'Copy Phone Number',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _shopLogo(String? logoUrl, String name) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          width: 88,
          height: 88,
          fit: BoxFit.cover,
          placeholder: (context, url) => _placeholderLogo(name),
          errorWidget: (context, url, error) => _placeholderLogo(name),
        ),
      );
    }
    return _placeholderLogo(name);
  }

  Widget _placeholderLogo(String name) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.navy),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.navy),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark)),
            ],
          ),
        ),
      ],
    );
  }

  void _copyPhone(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone number copied'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
