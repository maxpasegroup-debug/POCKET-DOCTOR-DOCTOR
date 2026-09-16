import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocket_doctor_doctor/core/networking/api_client.dart';
import 'package:pocket_doctor_doctor/features/auth/auth_controller.dart';
import 'package:pocket_doctor_doctor/features/registration/credential_image_preview.dart';
import 'package:pocket_doctor_doctor/features/registration/registration_repository.dart';

void main() {
  testWidgets(
    'private image preview retries authorized fetch and renders bytes',
    (tester) async {
      var requests = 0;
      final api = ApiClient(
        'https://example.test/api/v1',
        transport: MockClient((r) async {
          expect(r.url.path, '/api/v1/doctor/registration/documents/doc-a');
          expect(r.headers['Authorization'], 'Bearer test-session');
          if (++requests == 1) return http.Response('', 503);
          return http.Response(
            jsonEncode({
              'data': {
                'contentType': 'image/png',
                'contentBase64':
                  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gMQFwcdLl4wmwAAAAtJREFUCNdjYAACAAAFAAHiJgWbAAAAAElFTkSuQmCC',
              },
            }),
            200,
          );
        }),
      )..setToken('test-session');
      addTearDown(api.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiProvider.overrideWithValue(api)],
          child: MaterialApp(
            home: Scaffold(
              body: CredentialImagePreview(
                document: RegistrationDocument.fromJson({
                  'id': 'doc-a',
                  'kind': 'PROFILE_PHOTO',
                  'fileName': 'photo.png',
                  'size': 68,
                }),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not load the uploaded image.'), findsOneWidget);
      await tester.tap(find.text('Retry image preview'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<MemoryImage>(),
      );
      expect(requests, 2);
      expect(tester.takeException(), isNull);
    },
  );

  test('preview rejects non-image content from backend', () async {
    final api = ApiClient(
      'https://example.test/api/v1',
      transport: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': {'contentType': 'application/pdf', 'contentBase64': ''},
          }),
          200,
        ),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      RegistrationRepository(api).image('doc-a'),
      throwsException,
    );
  });
}
