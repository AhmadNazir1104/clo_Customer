import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_helper.dart';

/// Tracks whether the interstitial was already shown today.
/// Shows it at most once per day (stored in SharedPreferences).
class InterstitialAdManager {
  InterstitialAd? _ad;
  bool _isLoaded = false;

  void load() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoaded = true;
          _ad!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (_) {
          _isLoaded = false;
        },
      ),
    );
  }

  /// Shows the interstitial once per day. Calls [onDone] after dismiss.
  Future<void> showIfReady({required void Function() onDone}) async {
    if (!_isLoaded || _ad == null) {
      onDone();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString('interstitial_last_shown') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD

    if (lastShown == today) {
      // Already shown today — skip
      onDone();
      return;
    }

    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        _isLoaded = false;
        onDone();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _ad = null;
        _isLoaded = false;
        onDone();
      },
    );

    await prefs.setString('interstitial_last_shown', today);
    _ad!.show();
  }

  void dispose() {
    _ad?.dispose();
  }
}

final interstitialAdManagerProvider =
    Provider<InterstitialAdManager>((ref) {
  final manager = InterstitialAdManager();
  ref.onDispose(manager.dispose);
  return manager;
});
