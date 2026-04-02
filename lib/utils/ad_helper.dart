import 'dart:io';

/// Central place for all AdMob ad unit IDs.
/// Swap test IDs → real IDs before releasing to production.
class AdHelper {
  AdHelper._();

  // ── TEST IDs ─────────────────────────────────────────────────────────────
  // Using Google's official test IDs during development.
  // TODO: swap back to real IDs before releasing to production.
  static String get bannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    if (Platform.isIOS)     return 'ca-app-pub-3940256099942544/2934735716';
    throw UnsupportedError('Unsupported platform for ads');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    if (Platform.isIOS)     return 'ca-app-pub-3940256099942544/4411468910';
    throw UnsupportedError('Unsupported platform for ads');
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/2247696110';
    if (Platform.isIOS)     return 'ca-app-pub-3940256099942544/3986624511';
    throw UnsupportedError('Unsupported platform for ads');
  }

  // ── REAL IDs (uncomment when going to production) ─────────────────────
  // static String get bannerAdUnitId {
  //   if (Platform.isAndroid) return 'ca-app-pub-4587041607605021/9268635528';
  //   if (Platform.isIOS)     return 'ca-app-pub-4587041607605021/7281705788';
  //   throw UnsupportedError('Unsupported platform for ads');
  // }
  // static String get interstitialAdUnitId {
  //   if (Platform.isAndroid) return 'ca-app-pub-4587041607605021/1161982588';
  //   if (Platform.isIOS)     return 'ca-app-pub-4587041607605021/8047992548';
  //   throw UnsupportedError('Unsupported platform for ads');
  // }
  // static String get nativeAdUnitId {
  //   if (Platform.isAndroid) return 'ca-app-pub-4587041607605021/4850983561';
  //   if (Platform.isIOS)     return 'ca-app-pub-4587041607605021/8469626965';
  //   throw UnsupportedError('Unsupported platform for ads');
  // }

  /// Factory ID must match the string registered in
  /// MainActivity.kt (Android) and AppDelegate.swift (iOS).
  static const String nativeAdFactoryId = 'listTile';
}
