import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // ── AD UNIT IDs ──────────────────────────────────────────────────────────
  // TEST IDs (development ke liye) — real IDs AdMob account se milenge
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test
      // Production: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'
    } else {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS Test
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test
    } else {
      return 'ca-app-pub-3940256099942544/4411468910'; // iOS Test
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test
    } else {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS Test
    }
  }

  // ── INTERSTITIAL AD ──────────────────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  int _downloadCount = 0; // Every 3 downloads pe ad show

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitialIfReady() {
    _downloadCount++;
    // Har 3 downloads pe ek ad
    if (_downloadCount % 3 == 0 && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitialAd(); // reload for next time
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  // ── REWARDED AD ──────────────────────────────────────────────────────────
  RewardedAd? _rewardedAd;

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) => _rewardedAd = null,
      ),
    );
  }

  void showRewardedAd({required Function onRewarded}) {
    if (_rewardedAd == null) {
      // Ad not loaded — just give reward anyway (good UX)
      onRewarded();
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
      },
    );
    _rewardedAd!.show(
      onUserEarnedReward: (_, reward) => onRewarded(),
    );
    _rewardedAd = null;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
