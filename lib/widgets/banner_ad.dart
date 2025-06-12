import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:puzzle_master/helpers/banner_ad_helper.dart';

class BannerAdUnit extends StatefulWidget {
  const BannerAdUnit({super.key});

  @override
  State<BannerAdUnit> createState() => _BannerAdUnitState();

}

class _BannerAdUnitState extends State<BannerAdUnit> {
  
  late BannerAd _bannerAd;
  bool isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: BannerAdHelper.adUnitId,
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            isBannerAdLoaded = false;
          });
        },
      ),
      request: const AdRequest(),
    );
    _bannerAd.load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isBannerAdLoaded)
          Container(
            alignment: Alignment.center,
            width: _bannerAd.size.width.toDouble(),
            height: _bannerAd.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd),
          ),
        const SizedBox(height: 10), // Add some spacing below the ad
      ],
    );
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }
}