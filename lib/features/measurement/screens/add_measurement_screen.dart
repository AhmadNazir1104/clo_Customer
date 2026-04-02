import 'package:clocustomer/features/measurement/view_model/measurements_view_model.dart';
import 'package:clocustomer/model/measurement_entry_model.dart';
import 'package:clocustomer/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddMeasurementScreen extends ConsumerStatefulWidget {
  const AddMeasurementScreen({super.key});

  @override
  ConsumerState<AddMeasurementScreen> createState() =>
      _AddMeasurementScreenState();
}

class _AddMeasurementScreenState
    extends ConsumerState<AddMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  late final Map<String, TextEditingController> _fieldCtrls;
  final List<({TextEditingController name, TextEditingController value})>
      _customFields = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fieldCtrls = {
      for (final f in MeasurementEntry.standardFields)
        f: TextEditingController(),
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    for (final c in _fieldCtrls.values) { c.dispose(); }
    for (final cf in _customFields) {
      cf.name.dispose();
      cf.value.dispose();
    }
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final anyFilled = _fieldCtrls.entries.any((e) {
      final t = e.value.text.trim();
      if (MeasurementEntry.textOnlyFields.contains(e.key)) return t.isNotEmpty;
      return (double.tryParse(t) ?? 0) > 0;
    }) || _customFields.any(
        (cf) => cf.name.text.trim().isNotEmpty && cf.value.text.trim().isNotEmpty);

    if (!anyFilled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in at least one measurement field'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSaving = true);

    final numericFields = <String, double>{};
    final textFields = <String, String>{};

    for (final field in MeasurementEntry.standardFields) {
      final text = _fieldCtrls[field]!.text.trim();
      if (MeasurementEntry.textOnlyFields.contains(field)) {
        if (text.isNotEmpty) textFields[field] = text;
      } else {
        final val = double.tryParse(text);
        if (val != null && val > 0) numericFields[field] = val;
      }
    }

    final customFieldsMap = <String, String>{};
    for (final cf in _customFields) {
      final n = cf.name.text.trim();
      final v = cf.value.text.trim();
      if (n.isNotEmpty && v.isNotEmpty) customFieldsMap[n] = v;
    }

    try {
      await saveMyMeasurement(
        name: _nameCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        numericFields: numericFields,
        textFields: textFields,
        customFields: customFieldsMap,
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Custom field dialog ───────────────────────────────────────────────────

  void _showAddCustomFieldDialog() {
    final nameCtrl  = TextEditingController();
    final valueCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Custom Field',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.dark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(nameCtrl, 'Field name', 'e.g. Kurta Length'),
            const SizedBox(height: 12),
            _dialogField(valueCtrl, 'Value', 'e.g. 42"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () {
              final n = nameCtrl.text.trim();
              final v = valueCtrl.text.trim();
              Navigator.pop(ctx);
              if (n.isNotEmpty) {
                setState(() {
                  _customFields.add((
                    name: TextEditingController(text: n),
                    value: TextEditingController(text: v),
                  ));
                });
              }
              nameCtrl.dispose();
              valueCtrl.dispose();
            },
            child: const Text('Add',
                style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
      TextEditingController ctrl, String label, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.gray, fontSize: 13),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.navy, width: 2),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.dark),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Add My Sizes',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: AppColors.dark),
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.navy),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy)),
                ),
        ],
      ),
      // Info banner
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            // Info banner
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline,
                      size: 18, color: AppColors.navy),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your sizes are saved privately. '
                      'You can choose to share them with a shop later.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.navy.withValues(alpha: 0.85)),
                    ),
                  ),
                ],
              ),
            ),
            // Name & Note
            _sectionCard(
              child: Column(
                children: [
                  _nameField(),
                  const Divider(height: 24),
                  _noteField(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Standard fields
            _sectionHeader(
                'Standard Measurements', 'Enter in inches (e.g. 17.5)'),
            const SizedBox(height: 8),
            _sectionCard(
              child: Column(
                children: [
                  for (int i = 0;
                      i < MeasurementEntry.standardFields.length;
                      i++) ...[
                    _standardFieldRow(
                        MeasurementEntry.standardFields[i]),
                    if (i < MeasurementEntry.standardFields.length - 1)
                      const Divider(
                          height: 1, indent: 16, endIndent: 16),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Custom fields
            _sectionHeader(
                'Custom Fields', 'Add fields not listed above'),
            const SizedBox(height: 8),
            if (_customFields.isNotEmpty)
              _sectionCard(
                child: Column(
                  children: [
                    for (int i = 0; i < _customFields.length; i++) ...[
                      _customFieldRow(i),
                      if (i < _customFields.length - 1)
                        const Divider(
                            height: 1, indent: 16, endIndent: 16),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _showAddCustomFieldDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.navy),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Custom Field',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
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
      child: child,
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark)),
          Text(subtitle,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.gray)),
        ],
      ),
    );
  }

  Widget _nameField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: TextFormField(
        controller: _nameCtrl,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.dark),
        decoration: const InputDecoration(
          labelText: 'Entry name *',
          hintText: 'e.g. My Shirt Size, Summer Suit',
          hintStyle:
              TextStyle(color: AppColors.gray, fontSize: 13),
          border: InputBorder.none,
          labelStyle:
              TextStyle(color: AppColors.gray, fontSize: 13),
        ),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? 'Name is required'
            : null,
      ),
    );
  }

  Widget _noteField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: TextField(
        controller: _noteCtrl,
        maxLines: 2,
        minLines: 1,
        style:
            const TextStyle(fontSize: 14, color: AppColors.dark),
        decoration: const InputDecoration(
          labelText: 'Note (optional)',
          hintText: 'e.g. These are my summer measurements',
          hintStyle:
              TextStyle(color: AppColors.gray, fontSize: 13),
          border: InputBorder.none,
          labelStyle:
              TextStyle(color: AppColors.gray, fontSize: 13),
        ),
      ),
    );
  }

  Widget _standardFieldRow(String field) {
    final isText =
        MeasurementEntry.textOnlyFields.contains(field);
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(field,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: TextField(
              controller: _fieldCtrls[field],
              textAlign: TextAlign.end,
              keyboardType: isText
                  ? TextInputType.text
                  : const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: isText
                  ? []
                  : [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*')),
                    ],
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark),
              decoration: InputDecoration(
                hintText: isText ? '—' : '0.0',
                hintStyle: const TextStyle(
                    color: AppColors.gray, fontSize: 13),
                suffixText: isText ? '' : '"',
                suffixStyle: const TextStyle(
                    color: AppColors.gray, fontSize: 12),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customFieldRow(int index) {
    final cf = _customFields[index];
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(cf.name.text,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: TextField(
              controller: cf.value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark),
              decoration: const InputDecoration(
                hintText: '—',
                hintStyle:
                    TextStyle(color: AppColors.gray, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              cf.name.dispose();
              cf.value.dispose();
              setState(() => _customFields.removeAt(index));
            },
            child: const Icon(Icons.remove_circle_outline,
                size: 18, color: AppColors.red),
          ),
        ],
      ),
    );
  }
}
