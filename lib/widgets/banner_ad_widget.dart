// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import '../config/ads_config.dart';

// class BannerAdWidget extends StatefulWidget {
//   const BannerAdWidget({super.key});

//   @override
//   State<BannerAdWidget> createState() => _BannerAdWidgetState();
// }

// class _BannerAdWidgetState extends State<BannerAdWidget> {
//   BannerAd? _bannerAd;
//   bool _isAdLoaded = false;
//   String? _adError;

//   @override
//   void initState() {
//     super.initState();
//     if (!kIsWeb) {
//       _loadBannerAd();
//     }
//   }

//   void _loadBannerAd() {
//     try {
//       _bannerAd = BannerAd(
//         adUnitId: AdsConfig.bannerAdUnitId,
//         size: AdSize.banner,
//         request: const AdRequest(),
//         listener: BannerAdListener(
//           onAdLoaded: (ad) {
//             if (mounted) {
//               setState(() {
//                 _isAdLoaded = true;
//                 _adError = null;
//               });
//             }
//           },
//           onAdFailedToLoad: (ad, error) {
//             debugPrint('Ad failed to load: ${error.message}');
//             if (mounted) {
//               setState(() {
//                 _adError = error.message;
//               });
//             }
//             ad.dispose();
//           },
//           onAdOpened: (ad) => debugPrint('Ad opened'),
//           onAdClosed: (ad) => debugPrint('Ad closed'),
//         ),
//       );
//       _bannerAd?.load();
//     } catch (e) {
//       debugPrint('Error loading banner ad: $e');
//       if (mounted) {
//         setState(() {
//           _adError = e.toString();
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _bannerAd?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (kIsWeb) return const SizedBox.shrink();

//     return Container(
//       height: 50,
//       alignment: Alignment.center,
//       child: _isAdLoaded && _bannerAd != null
//           ? AdWidget(ad: _bannerAd!)
//           : _adError != null
//               ? Text(
//                   'Ad failed to load: $_adError',
//                   style: const TextStyle(color: Colors.red),
//                 )
//               : const CircularProgressIndicator(),
//     );
//   }
// } 