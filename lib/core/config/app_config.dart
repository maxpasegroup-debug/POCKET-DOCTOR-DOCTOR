import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig(String value, {bool release = kReleaseMode}) {
    final uri = Uri.tryParse(value);
    final local =
        uri != null &&
        ['localhost', '127.0.0.1', '::1', '10.0.2.2'].contains(uri.host);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !RegExp(r'^/api/v1/?$').hasMatch(uri.path) ||
        (uri.scheme != 'https' &&
            !(uri.scheme == 'http' && local && !release))) {
      throw const FormatException(
        'Configure API_BASE_URL with an HTTPS /api/v1 address.',
      );
    }
    baseUrl = value.replaceFirst(RegExp(r'/$'), '');
  }
  late final String baseUrl;
}
