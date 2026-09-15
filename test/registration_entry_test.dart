import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocket_doctor_doctor/core/networking/api_client.dart';
import 'package:pocket_doctor_doctor/features/auth/auth_controller.dart';
import 'package:pocket_doctor_doctor/features/auth/login_screen.dart';

void main() {
  Future<List<http.Request>> launch(
    WidgetTester tester,
    String errorCode,
  ) async {
    final calls = <http.Request>[];
    final api = ApiClient(
      'https://example.test/api/v1',
      transport: MockClient((r) async {
        calls.add(r);
        if (r.url.path == '/api/v1/doctor/registration/otp/request' &&
            errorCode == 'DOCTOR_REGISTRATION_REQUIRED') {
          expect(jsonDecode(r.body), {'phone': '+919999910001'});
          return http.Response(
            jsonEncode({
              'data': {'challengeId': 'synthetic-challenge'},
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'error': {'code': errorCode},
          }),
          errorCode == 'DOCTOR_REGISTRATION_REQUIRED' ? 409 : 403,
        );
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiProvider.overrideWithValue(api)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets(
    'new Doctor sign-in directs registration and same number proceeds to OTP',
    (tester) async {
      final calls = await launch(tester, 'DOCTOR_REGISTRATION_REQUIRED');
      await tester.enterText(find.byType(TextFormField), '+919999910001');
      await tester.tap(find.text('Send verification code'));
      await tester.pumpAndSettle();
      expect(jsonDecode(calls.single.body), {
        'phone': '+919999910001',
        'context': 'DOCTOR',
      });
      expect(
        find.text(
          'No doctor account exists yet. Choose Register as Doctor to apply.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Register as Doctor'));
      await tester.tap(find.text('Register as Doctor'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Send verification code'));
      await tester.tap(find.text('Send verification code'));
      await tester.pumpAndSettle();
      expect(find.text('Verification code'), findsOneWidget);
      expect(find.text('Verify & continue'), findsOneWidget);
      expect(calls.length, 2);
      expect(tester.takeException(), isNull);
    },
  );
  for (final entry in {
    'REGISTRATION_NOT_ALLOWED':
        'This account cannot register as a new doctor. Contact the platform team.',
    'DOCTOR_LOGIN_NOT_ALLOWED':
        'This account cannot sign in to the Doctor app. Use your linked doctor number or contact the platform team.',
  }.entries) {
    testWidgets('${entry.key} stays blocked and displays the backend error', (
      tester,
    ) async {
      final calls = await launch(tester, entry.key);
      if (entry.key == 'REGISTRATION_NOT_ALLOWED') {
        await tester.tap(find.text('Register as Doctor'));
        await tester.pumpAndSettle();
      }
      await tester.enterText(find.byType(TextFormField), '+919999910001');
      await tester.tap(find.text('Send verification code'));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      expect(find.text('Verification code'), findsNothing);
      expect(calls.length, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
