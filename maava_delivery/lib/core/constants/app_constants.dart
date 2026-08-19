import 'dart:io';

import 'package:maava_delivery/features/language/domain/models/language_listing_model.dart';

class AppConstants {
  static const String title = 'MAAVA Delivery';

  /// Consumer-facing brand, used in share text and the referral ticket.
  static const String brandName = 'MAAVA Delivery';
  static const String brandSuffix = 'Delivery';
  static const String appFontFamily = 'Latin';

  /// One backend for both verticals.
  ///
  /// The rider fleet is shared: `/delivery/*` is mounted cross-vertical on the
  /// server, so a single host serves food and quick jobs alike and this app
  /// never picks a vertical. Overridable at build time so a staging build needs
  /// no code edit:
  ///   flutter build apk --dart-define=API_HOST=https://staging.example.com
  static const String apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'https://maava.in',
  );
  static const String baseUrl = '$apiHost/api/v1';

  static String resolveMediaUrl(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('data:')) {
      return v;
    }
    final path = v.startsWith('/') ? v : '/$v';
    return '$apiHost$path';
  }

  static String firbaseApiKey = (Platform.isAndroid)
      ? "AIzaSyC_twLhO7C21HdRBvoZvedceka0jdLCUjc"
      : "ios firebase api key";

  static String firebaseAppId = (Platform.isAndroid)
      ? "1:592916974677:android:5366c1825a27cf201518dc"
      : "ios firebase app id";

  static String firebasemessagingSenderId = (Platform.isAndroid)
      ? "592916974677"
      : "ios firebase sender id";

  static String firebaseProjectId = (Platform.isAndroid)
      ? "flutterfoodapp-e6742"
      : "ios firebase project id";

  static String mapKey = (Platform.isAndroid)
      ? 'AIzaSyArBbII2fgAuVaycfkEAm1GcuyvKPTSWyc'
      : 'your ios map key';

  static const String stripPublishKey = '';

  static List<LocaleLanguageList> languageList = [
    LocaleLanguageList(name: 'English', lang: 'en'),
  ];

  static String packageName = 'com.appzetofood.delivery';
  static String signKey = '';
}
