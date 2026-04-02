import 'package:clocustomer/features/shop/view_model/shop_view_model.dart';
import 'package:clocustomer/l10n/app_localizations.dart';
import 'package:clocustomer/model/order_model.dart';
import 'package:clocustomer/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends ConsumerWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n  = AppLocalizations.of(context)!;
    final shop  = ref.watch(shopProvider(order.shopId));
    final color = _statusColor(order.status);
    final label = _statusLabel(order.status);
    final df    = DateFormat('d MMM yyyy');

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
          order.orderNumber,
          style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.dark),
        ),
        actions: [
          // Shop detail button
          shop.whenOrNull(
                data: (s) => s != null
                    ? TextButton(
                        onPressed: () =>
                            context.push('/shops/${order.shopId}'),
                        child: Text(
                          s.name,
                          style: const TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w600),
                        ),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Status banner ────────────────────────────────────────────
          _card(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_statusIcon(order.status), color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: color)),
                    Text(
                      'Due: ${df.format(order.dueDate)}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.gray),
                    ),
                  ],
                ),
                if (order.isOverdue) ...[
                  const Spacer(),
                  _warningBadge(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Items ────────────────────────────────────────────────────
          _sectionTitle('Items'),
          _card(
            child: Column(
              children: [
                for (final item in order.items) ...[
                  _itemRow(item),
                  if (item != order.items.last)
                    const Divider(height: 16),
                ],
                if (order.items.isEmpty)
                  const Text('No items',
                      style: TextStyle(color: AppColors.gray)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Payment ──────────────────────────────────────────────────
          _sectionTitle(l10n.totalAmount),
          _card(
            child: Column(
              children: [
                _payRow(l10n.totalAmount,
                    'Rs ${order.totalAmount.toStringAsFixed(0)}',
                    bold: true),
                const Divider(height: 16),
                _payRow(l10n.advancePaid,
                    'Rs ${order.advancePaid.toStringAsFixed(0)}'),
                if (order.additionalPayments.isNotEmpty) ...[
                  for (final p in order.additionalPayments)
                    _payRow(
                      '+ ${_paymentMethodLabel(p.method)}',
                      'Rs ${p.amount.toStringAsFixed(0)}',
                    ),
                ],
                const Divider(height: 16),
                _payRow(
                  l10n.remaining,
                  'Rs ${order.remainingDue.toStringAsFixed(0)}',
                  valueColor: order.remainingDue > 0
                      ? AppColors.orange
                      : AppColors.green,
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Photos ───────────────────────────────────────────────────
          if (order.photoUrls.isNotEmpty) ...[
            _sectionTitle('Photos'),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.photoUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: order.photoUrls[i],
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade100,
                      width: 110, height: 110,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.gray),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade100,
                      width: 110, height: 110,
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppColors.gray),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // ── Notes ────────────────────────────────────────────────────
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            _sectionTitle('Notes'),
            _card(
              child: Text(order.notes!,
                  style: const TextStyle(fontSize: 14, color: AppColors.dark)),
            ),
            const SizedBox(height: 12),
          ],
          // ── Fabric source ────────────────────────────────────────────
          _sectionTitle('Details'),
          _card(
            child: Column(
              children: [
                _infoRow('Fabric',
                    order.fabricSource == FabricSource.customer
                        ? 'Provided by customer'
                        : 'Provided by shop'),
                const Divider(height: 16),
                _infoRow('Ordered on',
                    DateFormat('d MMM yyyy').format(order.createdAt)),
                if (order.assignedStaffName != null) ...[
                  const Divider(height: 16),
                  _infoRow('Tailor', order.assignedStaffName!),
                ],
              ],
            ),
          ),
        ],
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
              color: AppColors.shadowLight, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.gray,
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _itemRow(OrderItemModel item) {
    return Row(
      children: [
        Expanded(
          child: Text(item.name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark)),
        ),
        Text(
          '× ${item.quantity}',
          style: const TextStyle(fontSize: 14, color: AppColors.gray),
        ),
        const SizedBox(width: 16),
        Text(
          'Rs ${(item.price * item.quantity).toStringAsFixed(0)}',
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.dark),
        ),
      ],
    );
  }

  Widget _payRow(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? AppColors.dark)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.gray)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark)),
        ),
      ],
    );
  }

  Widget _warningBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        border: Border.all(color: AppColors.warningBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Overdue',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.warningText),
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

IconData _statusIcon(OrderStatus s) => switch (s) {
      OrderStatus.pending    => Icons.hourglass_empty,
      OrderStatus.inProgress => Icons.construction,
      OrderStatus.ready      => Icons.check_circle_outline,
      OrderStatus.delivered  => Icons.local_shipping_outlined,
      OrderStatus.cancelled  => Icons.cancel_outlined,
    };

String _paymentMethodLabel(PaymentMethod m) => switch (m) {
      PaymentMethod.cash      => 'Cash',
      PaymentMethod.easypaisa => 'Easypaisa',
      PaymentMethod.jazzcash  => 'JazzCash',
    };
