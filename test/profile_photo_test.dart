import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocket_doctor_doctor/core/networking/api_client.dart';
import 'package:pocket_doctor_doctor/features/auth/auth_controller.dart';
import 'package:pocket_doctor_doctor/features/profile/profile_photo.dart';
import 'package:pocket_doctor_doctor/features/registration/credential_image_preview.dart';
import 'registration_test.dart' show application;

void main() {
  for (final scenario in [
    'photo',
    'no photo',
    'legacy account',
    'unavailable',
  ]) {
    testWidgets('profile photo handles $scenario without showing credentials', (
      tester,
    ) async {
      final calls = <String>[];
      final api = ApiClient(
        'https://example.test/api/v1',
        transport: MockClient((r) async {
          calls.add(r.url.path);
          expect(r.headers['Authorization'], 'Bearer own-session');
          if (r.url.path.endsWith('/documents/photo-id')) {
            // Preview failure stays local to the image and offers its own retry.
            return http.Response('', 503);
          }
          expect(r.url.path, '/api/v1/doctor/registration');
          if (scenario == 'legacy account') return http.Response('', 404);
          if (scenario == 'unavailable') return http.Response('', 503);
          final data = application('VERIFIED');
          if (scenario == 'photo') {
            (data['documents'] as List).add({
              'id': 'photo-id',
              'kind': 'PROFILE_PHOTO',
              'fileName': 'portrait.png',
              'size': 68,
            });
          }
          return http.Response(jsonEncode({'data': data}), 200);
        }),
      )..setToken('own-session');
      addTearDown(api.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiProvider.overrideWithValue(api)],
          child: const MaterialApp(home: Scaffold(body: ProfilePhoto())),
        ),
      );
      await tester.pumpAndSettle();
      if (scenario == 'photo') {
        expect(
          tester
              .widget<CredentialImagePreview>(
                find.byType(CredentialImagePreview),
              )
              .document
              .id,
          'photo-id',
        );
        expect(calls, [
          '/api/v1/doctor/registration',
          '/api/v1/doctor/registration/documents/photo-id',
        ]);
      } else if (scenario == 'unavailable') {
        expect(find.text('Retry profile photo'), findsOneWidget);
      } else {
        expect(find.text('No profile photo uploaded.'), findsOneWidget);
        expect(calls.length, 1);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
