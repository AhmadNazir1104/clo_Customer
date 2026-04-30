import 'package:khayyat/features/auth/view_model/auth_provider.dart';
import 'package:khayyat/features/auth/view_model/linked_shops_provider.dart';
import 'package:khayyat/features/order/view_model/orders_view_model.dart';
import 'package:khayyat/l10n/app_localizations.dart';
import 'package:khayyat/model/order_model.dart';
import 'package:khayyat/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure shops are linked if not already loaded
    Future.microtask(() {
      final phone     = ref.read(currentPhoneProvider);
      final firestore = ref.read(firestoreProvider);
      ref.read(linkedShopsProvider.notifier).loadAndLink(phone, firestore);

    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n       = AppLocalizations.of(context)!;
    final ordersAsync = ref.watch(allOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          l10n.myOrders,
          style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.dark),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _buildError(context, l10n, e.toString()),
        data:    (orders) => orders.isEmpty
            ? _buildEmpty(l10n)
            : _buildList(orders, l10n),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(l10n.noOrders,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, AppLocalizations l10n, String detail) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red),
            const SizedBox(height: 12),
            Text(l10n.errorOccurred,
                style: const TextStyle(fontSize: 16, color: AppColors.gray)),
            const SizedBox(height: 8),
            SelectableText(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.gray),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                final phone     = ref.read(currentPhoneProvider);
                final firestore = ref.read(firestoreProvider);
                ref.read(linkedShopsProvider.notifier).loadAndLink(phone, firestore);
              },
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<OrderModel> orders, AppLocalizations l10n) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: orders.length,
      itemBuilder: (context, i) => _OrderCard(
        order: orders[i],
        onTap: () => context.push('/orders/detail', extra: orders[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order Card
// ─────────────────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    final label = _statusLabel(order.status);
    final df    = DateFormat('d MMM yyyy');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ────────────────────────────────────────────
              Row(
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.dark),
                  ),
                  const Spacer(),
                  _StatusChip(label: label, color: color),
                ],
              ),
              const SizedBox(height: 10),
              // ── Items ─────────────────────────────────────────────────
              Text(
                order.items.map((i) => i.name).join(', '),
                style: const TextStyle(fontSize: 14, color: AppColors.gray),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // ── Footer row ────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.gray),
                  const SizedBox(width: 4),
                  Text(
                    df.format(order.dueDate),
                    style: const TextStyle(fontSize: 13, color: AppColors.gray),
                  ),
                  const Spacer(),
                  if (order.remainingDue > 0)
                    _DueChip(amount: order.remainingDue),
                  if (order.isFullyPaid)
                    const _PaidChip(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _DueChip extends StatelessWidget {
  final double amount;
  const _DueChip({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Due: Rs ${amount.toStringAsFixed(0)}',
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.orange),
      ),
    );
  }
}

class _PaidChip extends StatelessWidget {
  const _PaidChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Paid',
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Color _statusColor(OrderStatus s) => switch (s) {
      OrderStatus.pending    => AppColors.orange,
      OrderStatus.inProgress => AppColors.navy,
      OrderStatus.ready      => AppColors.green,
      OrderStatus.delivered  => AppColors.gray,
      OrderStatus.cancelled  => AppColors.red,
    };

String _statusLabel(OrderStatus s) => switch (s) {
      OrderStatus.pending    => 'Pending',
      OrderStatus.inProgress => 'In Progress',
      OrderStatus.ready      => 'Ready',
      OrderStatus.delivered  => 'Delivered',
      OrderStatus.cancelled  => 'Cancelled',
    };
