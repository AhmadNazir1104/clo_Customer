/// Normalizes any Pakistani phone number format to the canonical local format
/// used as Firestore document IDs and query values: `03XXXXXXXXX` (11 digits).
///
/// Handles every common input variant:
///   +923001234567  →  03001234567
///   923001234567   →  03001234567
///   03001234567    →  03001234567  (already canonical)
///    3001234567    →  03001234567  (10 digits, missing leading 0)
///
/// Also strips spaces, dashes, and brackets before processing.
String normalizeToLocal(String phone) {
  final p = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

  if (p.startsWith('+92')) return '0${p.substring(3)}';           // +92 3XXXXXXXXX
  if (p.startsWith('92') && p.length >= 12) return '0${p.substring(2)}'; // 92 3XXXXXXXXX
  if (p.startsWith('0')) return p;                                 // 0 3XXXXXXXXX
  if (p.length == 10 && p.startsWith('3')) return '0$p';          // 3XXXXXXXXX (missing 0)

  return p; // unknown format — return as-is
}

/// Formats any Pakistani phone number for display as `+92XXXXXXXXXX`.
///
/// Regardless of how the number is stored, the user always sees the
/// international format:  +92 300 1234567
String formatForDisplay(String phone) {
  final local = normalizeToLocal(phone);
  if (local.startsWith('0') && local.length == 11) {
    return '+92${local.substring(1)}';
  }
  return phone; // fallback — return original if format is unrecognised
}
