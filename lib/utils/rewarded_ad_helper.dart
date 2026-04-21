import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Rewarded ads (Android / iOS). On desktop/web, returns [true] so bonus can be tested.
class RewardedAdHelper {
  RewardedAdHelper._();

  static bool get supported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static String get _unitId {
    return defaultTargetPlatform == TargetPlatform.android
        ? 'ca-app-pub-3940256099942544/5224354917'
        : 'ca-app-pub-3940256099942544/1712485313';
  }

  /// Loads and shows one rewarded ad. Completes with `true` if user earned reward.
  /// On non-mobile, completes with `true` (demo) so RPC can still be tested.
  static Future<bool> showRewardedForBonus() async {
    if (!supported) {
      return true;
    }

    final completer = Completer<bool>();
    var earned = false;

    await RewardedAd.load(
      adUnitId: _unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(earned);
              }
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(false);
              }
            },
          );
          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              earned = true;
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    return completer.future.timeout(
      const Duration(seconds: 120),
      onTimeout: () => false,
    );
  }
}
