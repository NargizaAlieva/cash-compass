import 'package:flutter/foundation.dart';

/// App settings.
class AppConfig {
  /// The server on Render. Release builds (the APK for a phone) use it.
  static const productionUrl = 'https://cash-compass-api.onrender.com';

  /// Server address.
  ///
  /// Can be overridden at launch:
  /// flutter run --dart-define=API_URL=http://192.168.1.10:8000
  static String get baseUrl {
    const fromEnvironment = String.fromEnvironment('API_URL');
    if (fromEnvironment.isNotEmpty) {
      return fromEnvironment;
    }
    // flutter build apk / flutter run --release -> the real server
    if (kReleaseMode) {
      return productionUrl;
    }
    // Android emulator sees the computer as 10.0.2.2, not localhost
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}