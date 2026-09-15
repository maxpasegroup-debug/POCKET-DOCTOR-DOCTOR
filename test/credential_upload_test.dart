import 'dart:async';
import 'registration_test.dart' show application;
import 'package:pocket_doctor_doctor/features/auth/auth_controller.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocket_doctor_doctor/core/networking/api_client.dart';
import 'package:pocket_doctor_doctor/features/registration/registration_repository.dart';

void main() {
  test(
    'replacement uploads use existing owned endpoint without owner or role selectors',
    () async {
      late http.Request request;
      final api = ApiClient(
        'https://example.test/api/v1',
        transport: MockClient((r) async {
          request = r;
          return http.Response(jsonEncode({'data': application('DRAFT')}), 200);
        }),
      );
      addTearDown(api.close);
      await RegistrationRepository(api).upload(
        'REGISTRATION',
        'test.pdf',
        'application/pdf',
        Uint8List.fromList([1, 2]),
        replaceDocumentId: 'document-id',
      );
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(request.url.path, '/api/v1/doctor/registration/documents');
      expect(body['replaceDocumentId'], 'document-id');
      expect(body.containsKey('doctorId'), false);
      expect(body.containsKey('role'), false);
    },
  );
  test(
    'upload state transitions from uploading to uploaded without claiming verified',
    () async {
      final response = Completer<http.Response>();
      final api = ApiClient(
        'https://example.test/api/v1',
        transport: MockClient((_) => response.future),
      );
      final container = ProviderContainer(
        overrides: [apiProvider.overrideWithValue(api)],
      );
      final subscription = container.listen(
        registrationControllerProvider,
        (_, _) {},
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
        api.close();
      });
      final action = container
          .read(registrationControllerProvider.notifier)
          .run(
            (r) => r.upload(
              'REGISTRATION',
              'test.pdf',
              'application/pdf',
              Uint8List(1),
            ),
            credentialKind: 'REGISTRATION',
          );
      expect(
        container.read(registrationControllerProvider).uploadPhase,
        CredentialUploadPhase.uploading,
      );
      response.complete(
        http.Response(jsonEncode({'data': application('DRAFT')}), 200),
      );
      expect(await action, true);
      expect(
        container.read(registrationControllerProvider).uploadPhase,
        CredentialUploadPhase.uploaded,
      );
    },
  );
  test(
    'storage failure is failed and retry can succeed without bypassing repository',
    () async {
      var calls = 0;
      final api = ApiClient(
        'https://example.test/api/v1',
        transport: MockClient(
          (_) async => ++calls == 1
              ? http.Response('', 503)
              : http.Response(jsonEncode({'data': application('DRAFT')}), 200),
        ),
      );
      final container = ProviderContainer(
        overrides: [apiProvider.overrideWithValue(api)],
      );
      final subscription = container.listen(
        registrationControllerProvider,
        (_, _) {},
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
        api.close();
      });
      Future<bool> upload() => container
          .read(registrationControllerProvider.notifier)
          .run(
            (r) => r.upload(
              'REGISTRATION',
              'test.pdf',
              'application/pdf',
              Uint8List(1),
            ),
            credentialKind: 'REGISTRATION',
          );
      expect(await upload(), false);
      expect(
        container.read(registrationControllerProvider).uploadPhase,
        CredentialUploadPhase.failed,
      );
      expect(container.read(registrationControllerProvider).error, isNotNull);
      expect(await upload(), true);
      expect(calls, 2);
    },
  );
}
