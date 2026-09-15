import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/networking/api_client.dart';
import 'features/auth/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  try {
    final config = AppConfig(const String.fromEnvironment('API_BASE_URL'));
    if (kDebugMode) {
      debugPrint('Doctor API host: ${Uri.parse(config.baseUrl).host}');
    }
    runApp(
      ProviderScope(
        overrides: [apiProvider.overrideWithValue(ApiClient(config.baseUrl))],
        child: const DoctorApp(),
      ),
    );
  } on FormatException catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(error.message),
            ),
          ),
        ),
      ),
    );
  }
}
