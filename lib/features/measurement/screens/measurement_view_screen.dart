import 'package:libaas/model/measurement_entry_model.dart';
import 'package:libaas/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MeasurementViewScreen extends StatelessWidget {
  final MeasurementEntry entry;

  const MeasurementViewScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final df          = DateFormat('d MMM yyyy');
    final allRows     = _buildRows();
    final hasAny      = allRows.isNotEmpty;

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
          entry.name,
          style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.dark),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Meta card ──────────────────────────────────────────────
          _MetaCard(entry: entry, df: df),
          const SizedBox(height: 16),
          // ── Measurements ───────────────────────────────────────────
          if (!hasAny)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 32),
                child: Text(
                  'No measurements recorded yet.',
                  style: TextStyle(fontSize: 15, color: AppColors.gray),
                ),
              ),
            )
          else ...[
            if (allRows.isNotEmpty) _FieldsCard(rows: allRows),
          ],
        ],
      ),
    );
  }

  /// Collects all filled fields in display order:
  /// standard numeric → standard text → custom
  List<_FieldRow> _buildRows() {
    final rows = <_FieldRow>[];

    // Standard numeric fields (in standardFields order)
    for (final key in MeasurementEntry.standardFields) {
      if (MeasurementEntry.textOnlyFields.contains(key)) {
        final val = entry.textFields[key] ?? '';
        if (val.isNotEmpty) rows.add(_FieldRow(label: key, value: val));
      } else {
        final val = entry.numericFields[key] ?? 0;
        if (val > 0) {
          rows.add(_FieldRow(label: key, value: _formatInches(val)));
        }
      }
    }

    // Any remaining numeric fields not in standardFields
    for (final e in entry.numericFields.entries) {
      if (!MeasurementEntry.standardFields.contains(e.key) && e.value > 0) {
        rows.add(_FieldRow(label: e.key, value: _formatInches(e.value)));
      }
    }

    // Any remaining text fields not in standardFields
    for (final e in entry.textFields.entries) {
      if (!MeasurementEntry.standardFields.contains(e.key) &&
          e.value.isNotEmpty) {
        rows.add(_FieldRow(label: e.key, value: e.value));
      }
    }

    // Custom fields
    for (final e in entry.customFields.entries) {
      if (e.value.isNotEmpty) {
        rows.add(_FieldRow(label: e.key, value: e.value, isCustom: true));
      }
    }

    return rows;
  }

  String _formatInches(double value) {
    final whole    = value.truncate();
    final fraction = value - whole;
    String frac = '';
    if ((fraction - 0.25).abs() < 0.01) {
      frac = ' ¼';
    } else if ((fraction - 0.5).abs() < 0.01) {
      frac = ' ½';
    } else if ((fraction - 0.75).abs() < 0.01) {
      frac = ' ¾';
    } else if (fraction > 0.01) {
      return '${value.toStringAsFixed(1)}"';
    }
    return '$whole$frac"';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MetaCard extends StatelessWidget {
  final MeasurementEntry entry;
  final DateFormat df;

  const _MetaCard({required this.entry, required this.df});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.1),
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
                    Text(
                      entry.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark),
                    ),
                    Text(
                      '${entry.filledCount} field${entry.filledCount == 1 ? '' : 's'} recorded',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.gray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (entry.note != null && entry.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 16, color: AppColors.gray),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.note!,
                    style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.gray),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.gray),
              const SizedBox(width: 6),
              Text(
                'Updated ${df.format(entry.updatedAt)}',
                style: const TextStyle(fontSize: 12, color: AppColors.gray),
              ),
              const Spacer(),
              Text(
                'Created ${df.format(entry.createdAt)}',
                style: const TextStyle(fontSize: 12, color: AppColors.gray),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FieldsCard extends StatelessWidget {
  final List<_FieldRow> rows;

  const _FieldsCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        if (rows[i].isCustom) ...[
                          const Icon(Icons.tune,
                              size: 14, color: AppColors.gray),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            rows[i].label,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.gray),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    rows[i].value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _FieldRow {
  final String label;
  final String value;
  final bool isCustom;

  const _FieldRow({
    required this.label,
    required this.value,
    this.isCustom = false,
  });
}
