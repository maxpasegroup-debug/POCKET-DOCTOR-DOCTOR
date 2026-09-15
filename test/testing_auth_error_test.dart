import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocket_doctor_doctor/core/errors/api_failure.dart';
import 'package:pocket_doctor_doctor/core/networking/api_client.dart';

void main() {
  for (final path in [
    '/auth/otp/request',
    '/doctor/registration/otp/request',
  ]) {
    test('testing eligibility has an accurate error for $path', () async {
      final api = ApiClient(
        'https://example.test/api/v1',
        transport: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {
                'code': 'TEST_LOGIN_NOT_ALLOWED',
                'message': 'private details',
              },
            }),
            403,
          ),
        ),
      );
      addTearDown(api.close);
      await expectLater(
        api.request(path, method: 'POST', body: {}),
        throwsA(
          isA<ApiFailure>().having(
            (e) => e.message,
            'message',
            'This account is not eligible for Doctor staging testing. Use your configured synthetic Doctor account; applicants should use registration.',
          ),
        ),
      );
    });
  }
  test(
    'genuine authorization failures retain their existing message',
    () async {
      final api = ApiClient(
        'https://example.test/api/v1',
        transport: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {'code': 'FORBIDDEN'},
            }),
            403,
          ),
        ),
      );
      addTearDown(api.close);
      await expectLater(
        api.request('/doctor/appointments'),
        throwsA(
          isA<ApiFailure>().having(
            (e) => e.message,
            'message',
            'A verified, assigned doctor account is required.',
          ),
        ),
      );
    },
  );
}
