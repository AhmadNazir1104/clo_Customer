import 'package:cloud_firestore/cloud_firestore.dart';

class MeasurementEntry {
  final String id;
  final String name;
  final String? note;
  final Map<String, double> numericFields;
  final Map<String, String> textFields;
  final Map<String, String> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? addedBy; // 'owner' | 'customer' — null means legacy (owner)
  final List<String> sharedWith; // shopIds this private entry is shared with

  bool get isAddedByCustomer => addedBy == 'customer';
  bool get isSharedWithAnyShop => sharedWith.isNotEmpty;
  bool isSharedWith(String shopId) => sharedWith.contains(shopId);

  const MeasurementEntry({
    required this.id,
    required this.name,
    this.note,
    required this.numericFields,
    required this.textFields,
    required this.customFields,
    required this.createdAt,
    required this.updatedAt,
    this.addedBy,
    this.sharedWith = const [],
  });

  static const List<String> standardFields = [
    'Neck (Gala)', 'Shoulder Width', 'Chest / Bust (Seena)', 'Under Bust',
    'Waist (Kamar)', 'Hip', 'Sleeve Length (Kol)', 'Armhole (Ghole)',
    'Bicep Width (Baazu)', 'Elbow Width', 'Wrist / Cuff Width',
    'Shirt / Top Length', 'Trouser / Bottom Length', 'Thigh Width',
    'Knee Width', 'Calf Width', 'Bottom Width (Paicha)',
    'Ghera / Hem Circumference', 'Front Neck Depth', 'Back Neck Depth',
    'Shoulder to Bust', 'Bust Span', 'Shoulder to Waist', 'Waist to Hip Length',
    'Full Length (Frock/Maxi/Sherwani)', 'Inseam (for Pants)', 'Pant Rise',
    'Side Slit Length (Chak)', 'Sleeve Style',
  ];

  static const Set<String> textOnlyFields = {'Sleeve Style'};

  int get filledCount =>
      numericFields.values.where((v) => v > 0).length +
      textFields.values.where((v) => v.isNotEmpty).length +
      customFields.values.where((v) => v.isNotEmpty).length;

  factory MeasurementEntry.fromMap(String id, Map<String, dynamic> map) {
    Map<String, double> toDoubleMap(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0.0));
    }

    Map<String, String> toStringMap(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    return MeasurementEntry(
      id: id,
      name: map['name'] as String? ?? '',
      note: map['note'] as String?,
      numericFields: toDoubleMap(map['numericFields']),
      textFields: toStringMap(map['textFields']),
      customFields: toStringMap(map['customFields']),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      addedBy: map['addedBy'] as String?,
      sharedWith: (map['sharedWith'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
