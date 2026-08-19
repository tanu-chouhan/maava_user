
class AppConstants {
  AppConstants._();

  static const String title = 'Appzeto Quick Delivery';

  /// Consumer-facing brand, used in share text, the referral ticket and the
  /// Razorpay checkout sheet. Change it here, not at the call sites.
  static const String brandName = 'Appzeto Quick Delivery';

  /// Second line of the stacked wordmark on the referral ticket.
  static const String brandSuffix = 'Delivery';
  static const String appFontFamily = 'Latin';

  /// Backend origin.
  ///
  /// Overridable at build time so a staging build never needs a code edit:
  ///   flutter build apk --dart-define=API_HOST=https://api.example.com
  static const String apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'https://quick.appzeto.com',
  );

  static const String baseUrl = '$apiHost/api/v1';

  /// Turns a backend-relative upload path (`/uploads/...`) into a full URL,
  /// leaving absolute and data URLs untouched.
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

  /// Google Maps key used for the Static Maps preview. The SDK map itself
  /// reads its key from the native manifests, not from here.
  static const String mapKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'AIzaSyArBbII2fgAuVaycfkEAm1GcuyvKPTSWyc',
  );

  static const String packageName = 'com.quickcommerce.delivery';
}
