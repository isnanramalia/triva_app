import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _localIp = '192.168.11.109';

  // Port local
  static const String _port = '8000';

  // URL Production (Nanti kalau sudah deploy ke VPS/Hosting)
  static const String _productionUrl = 'https://api.triva.com/api';

  // Logic Pintar memilih URL
  static String get baseUrl {
    if (kReleaseMode) {
      return _productionUrl;
    }

    if (!kReleaseMode && defaultTargetPlatform == TargetPlatform.android) {
    }

    return 'http://$_localIp:$_port/api';
  }
}
