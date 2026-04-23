import 'package:libaas/features/auth/view_model/auth_provider.dart';
import 'package:libaas/features/auth/view_model/linked_shops_provider.dart';
import 'package:libaas/features/measurement/view_model/measurements_view_model.dart';
import 'package:libaas/features/shop/view_model/shop_view_model.dart';
import 'package:libaas/l10n/app_localizations.dart';
import 'package:libaas/model/measurement_entry_model.dart';
import 'package:libaas/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MeasurementsHomeScreen extends ConsumerStatefulWidget {
  const MeasurementsHomeScreen({super.key});

  @override
  ConsumerState<MeasurementsHomeScreen> createState() =>
      _MeasurementsHomeScreenState();
}

class _MeasurementsHomeScreenState
    extends ConsumerState<MeasurementsHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final phone     = ref.read(currentPhoneProvider);
      final firestore = ref.read(firestoreProvider);
      ref.read(linkedShopsProvider.notifier).loadAndLink(phone, firestore);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context)!;
    final linked = ref.watch(linkedShopsProvider);
    final phone  = ref.watch(currentPhoneProvider);
    final myMeasurementsAsync = ref.watch(myMeasurementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          l10n.measurements,
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppColors.dark),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/measurements/add'),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add My Sizes',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // ── My Sizes section ──────────────────────────────────────
          _SectionHeader(
            icon: Icons.lock_outline,
            title: 'My Sizes',
            subtitle: 'Private — share with shops any time',
          ),
          const SizedBox(height: 8),
          myMeasurementsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: AppColors.gray)),
            data: (entries) {
              if (entries.isEmpty) {
                return _EmptyCard(
                  icon: Icons.straighten,
                  message: 'No sizes added yet.\nTap "Add My Sizes" to get started.',
                );
              }
              return Column(
                children: [
                  for (final entry in entries)
                    _MyMeasurementCard(
                      entry: entry,
                      shopIds: linked.shopIds,
                      phone: phone,
                      onTap: () => context.push(
                          '/measurements/view',
                          extra: entry),
                    ),
                ],
              );
            },
          ),
          // ── Shop measurements section ─────────────────────────────
          if (linked.shopIds.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.store_outlined,
              title: 'From Your Shops',
              subtitle: 'Sizes recorded by shop owners',
            ),
            const SizedBox(height: 8),
            if (linked.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              for (final shopId in linked.shopIds)
                _ShopOwnerMeasurementsSection(
                    shopId: shopId, phone: phone),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.navy),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.gray)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Sizes card — with share / revoke controls
// ─────────────────────────────────────────────────────────────────────────────

class _MyMeasurementCard extends ConsumerWidget {
  final MeasurementEntry entry;
  final List<String> shopIds;
  final String phone;
  final VoidCallback onTap;

  const _MyMeasurementCard({
    required this.entry,
    required this.shopIds,
    required this.phone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final df          = DateFormat('d MMM yyyy');
    final filledCount = entry.filledCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 6,
                offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // ── Main row ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.straighten,
                        color: AppColors.navy, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark)),
                        const SizedBox(height: 3),
                        Text(
                          filledCount > 0
                              ? '$filledCount field${filledCount == 1 ? '' : 's'} · ${df.format(entry.updatedAt)}'
                              : 'No data · ${df.format(entry.updatedAt)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.gray),
                        ),
                        if (entry.note != null &&
                            entry.note!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(entry.note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.gray)),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.gray, size: 20),
                ],
              ),
            ),
            // ── Share row ─────────────────────────────────────────
            if (shopIds.isNotEmpty) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    Icon(
                      entry.isSharedWithAnyShop
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 15,
                      color: entry.isSharedWithAnyShop
                          ? AppColors.teal
                          : AppColors.gray,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.isSharedWithAnyShop
                            ? 'Shared with ${entry.sharedWith.length} shop${entry.sharedWith.length == 1 ? '' : 's'}'
                            : 'Not shared with any shop',
                        style: TextStyle(
                            fontSize: 12,
                            color: entry.isSharedWithAnyShop
                                ? AppColors.teal
                                : AppColors.gray),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showShareSheet(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Manage',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ShareSheet(
        entry: entry,
        shopIds: shopIds,
        phone: phone,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Share / revoke bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ShareSheet extends ConsumerStatefulWidget {
  final MeasurementEntry entry;
  final List<String> shopIds;
  final String phone;

  const _ShareSheet({
    required this.entry,
    required this.shopIds,
    required this.phone,
  });

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  final Set<String> _busy = {};

  Future<void> _toggle(String shopId) async {
    setState(() => _busy.add(shopId));
    try {
      if (widget.entry.isSharedWith(shopId)) {
        await revokeFromShop(
          entryId: widget.entry.id,
          shopId: shopId,
          phone: widget.phone,
        );
      } else {
        await shareWithShop(
          entry: widget.entry,
          shopId: shopId,
          phone: widget.phone,
        );
      }
      // Close immediately on success — the card behind will update from stream
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _busy.remove(shopId));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            '"${widget.entry.name}"',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.dark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose which shops can view this measurement. '
            'You can revoke access at any time.',
            style: TextStyle(fontSize: 13, color: AppColors.gray),
          ),
          const SizedBox(height: 20),
          for (final shopId in widget.shopIds)
            _ShopToggleTile(
              shopId: shopId,
              isShared: widget.entry.isSharedWith(shopId),
              isBusy: _busy.contains(shopId),
              onToggle: () => _toggle(shopId),
            ),
        ],
      ),
    );
  }
}

class _ShopToggleTile extends ConsumerWidget {
  final String shopId;
  final bool isShared;
  final bool isBusy;
  final VoidCallback onToggle;

  const _ShopToggleTile({
    required this.shopId,
    required this.isShared,
    required this.isBusy,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopProvider(shopId));
    final name =
        shopAsync.whenOrNull(data: (s) => s?.name) ?? '...';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isShared
            ? AppColors.teal.withValues(alpha: 0.07)
            : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isShared
              ? AppColors.teal.withValues(alpha: 0.4)
              : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.store,
              color: AppColors.navy, size: 20),
        ),
        title: Text(name,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.dark)),
        subtitle: Text(
          isShared ? 'Has access' : 'No access',
          style: TextStyle(
              fontSize: 12,
              color:
                  isShared ? AppColors.teal : AppColors.gray),
        ),
        trailing: isBusy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.navy),
              )
            : Switch(
                value: isShared,
                onChanged: (_) => onToggle(),
                activeThumbColor: AppColors.teal,
                activeTrackColor: AppColors.teal.withValues(alpha: 0.4),
              ),
        onTap: isBusy ? null : onToggle,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shop owner measurements section (read-only)
// ─────────────────────────────────────────────────────────────────────────────

class _ShopOwnerMeasurementsSection extends ConsumerWidget {
  final String shopId;
  final String phone;

  const _ShopOwnerMeasurementsSection(
      {required this.shopId, required this.phone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopProvider(shopId));
    final entriesAsync = ref.watch(
        shopOwnerMeasurementsProvider((shopId: shopId, phone: phone)));

    final shopName =
        shopAsync.whenOrNull(data: (s) => s?.name) ?? '...';

    return entriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.store,
                      size: 14, color: AppColors.gray),
                  const SizedBox(width: 6),
                  Text(shopName,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray)),
                ],
              ),
            ),
            for (final entry in entries)
              _ReadOnlyEntryCard(
                entry: entry,
                onTap: () => context.push('/measurements/view',
                    extra: entry),
              ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _ReadOnlyEntryCard extends StatelessWidget {
  final MeasurementEntry entry;
  final VoidCallback onTap;

  const _ReadOnlyEntryCard(
      {required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy');
    final filledCount = entry.filledCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 6,
                offset: Offset(0, 2)),
          ],
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.gray.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.straighten,
                  color: AppColors.gray, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark)),
                  Text(
                    '$filledCount field${filledCount == 1 ? '' : 's'} · ${df.format(entry.updatedAt)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.gray),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.gray, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state card
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}
