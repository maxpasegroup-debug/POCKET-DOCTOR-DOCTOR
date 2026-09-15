import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocket_doctor_doctor/app.dart';
import 'package:pocket_doctor_doctor/core/networking/api_client.dart';
import 'package:pocket_doctor_doctor/features/auth/auth_controller.dart';
import 'package:pocket_doctor_doctor/features/registration/registration_repository.dart';
import 'fixtures.dart';
import 'package:timezone/data/latest_all.dart' as tz;

Map<String, dynamic> application(String status, {bool storage = true}) => {
  'id': 'application-a',
  'status': status,
  'phone': '+919999910001',
  'editable': ['DRAFT', 'REJECTED'].contains(status),
  'rejectionReason': status == 'REJECTED'
      ? 'Replace the registration certificate.'
      : null,
  'submittedAt': null,
  'profile': {
    'name': 'Synthetic Doctor',
    'registrationEmail': 'doctor@example.invalid',
    'registrationDateOfBirth': '1990-01-01',
    'registrationGender': '',
    'qualification': 'Synthetic qualification',
    'specialty': 'Education',
    'biography': 'Synthetic biography',
    'registrationAuthority': 'Synthetic council',
    'registrationNumber': 'TEST-001',
    'experienceYears': 4,
    'languages': ['English'],
    'feePaise': 10000,
  },
  'documents': storage
      ? [
          {
            'id': 'document-a',
            'kind': 'REGISTRATION',
            'fileName': 'synthetic.pdf',
            'size': 128,
          },
        ]
      : [],
  'documentPolicy': {
    'storageAvailable': storage,
    'configured': true,
    'requiredKinds': ['REGISTRATION'],
  },
};
void main() {
  test(
    'server document deferral permits review submission but not locked states',
    () {
      final draft = application('DRAFT', storage: false);
      (draft['documentPolicy'] as Map<String, dynamic>)['deferred'] = true;
      expect(RegistrationApplication.fromJson(draft).canSubmit, isTrue);
      final pending = application('SUBMITTED', storage: false);
      (pending['documentPolicy'] as Map<String, dynamic>)['deferred'] = true;
      expect(RegistrationApplication.fromJson(pending).canSubmit, isFalse);
    },
  );
  setUpAll(tz.initializeTimeZones);
  Future<List<http.Request>> launch(
    WidgetTester tester, {
    String status = 'DRAFT',
    bool storage = true,
    bool deferred = false,
    bool signedIn = true,
    bool ready = false,
    bool failLoad = false,
  }) async {
    final calls = <http.Request>[];
    var data = application(status, storage: storage);
    (data['documentPolicy'] as Map<String, dynamic>)['deferred'] = deferred;
    final store = MemoryStore()..token = signedIn ? 'test-session' : null;
    final api = ApiClient(
      'https://example.test/api/v1',
      transport: MockClient((r) async {
        calls.add(r);
        final path = r.url.path;
        if (path == '/api/v1/doctor/registration' && failLoad) {
          return http.Response('', 503);
        }
        if (path == '/api/v1/doctor/registration' && r.method == 'PATCH') {
          data = {...data, 'profile': jsonDecode(r.body)};
        }
        if (path.endsWith('/registration/submit')) {
          data = {...data, 'status': 'SUBMITTED', 'editable': false};
        }
        final response = switch (path) {
          '/api/v1/doctor/session' => {
            'status': ready ? 'READY' : 'PENDING_VERIFICATION',
            'doctor': ready ? doctorJson : null,
            'registration': {'required': !ready, 'status': data['status']},
          },
          '/api/v1/doctor/registration' => data,
          '/api/v1/doctor/registration/submit' => data,
          '/api/v1/doctor/registration/otp/request' => {
            'challengeId': 'test-challenge',
          },
          '/api/v1/doctor/registration/otp/verify' => {'token': 'test-session'},
          '/api/v1/doctor/profile' => {'doctor': doctorJson},
          '/api/v1/doctor/appointments' => {'consultations': []},
          _ => {'saved': true},
        };
        return http.Response(jsonEncode({'data': response}), 200);
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiProvider.overrideWithValue(api),
          sessionStoreProvider.overrideWithValue(store),
        ],
        child: const DoctorApp(),
      ),
    );
    await tester.pumpAndSettle();
    return calls;
  }

  Future<void> press(WidgetTester tester, String label) async {
    final f = find.text(label);
    if (find.byType(AlertDialog).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        f,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
    if (find.byType(ListView).evaluate().isNotEmpty) {
      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'Register entry uses purpose-bound OTP and enters draft, never Doctor Home',
    (tester) async {
      final calls = await launch(tester, signedIn: false);
      await press(tester, 'Register as Doctor');
      await tester.enterText(find.byType(TextFormField), '9999910001');
      await press(tester, 'Send verification code');
      expect(
        jsonDecode(
          calls.firstWhere((r) => r.url.path.endsWith('/otp/request')).body,
        )['phone'],
        '+919999910001',
      );
      await tester.enterText(find.byType(TextFormField), '123456');
      await press(tester, 'Verify & continue');
      expect(find.text('Step 1 of 4 · Basic information'), findsOneWidget);
      expect(find.text('Refresh agenda'), findsNothing);
      expect(
        calls.any(
          (r) => r.url.path == '/api/v1/doctor/registration/otp/verify',
        ),
        true,
      );
      expect(
        calls
            .where((r) => r.url.path.contains('/otp/'))
            .every((r) => !r.body.contains('role')),
        true,
      );
    },
  );
  testWidgets(
    'draft saves through all steps and submit becomes pending without operational access',
    (tester) async {
      final calls = await launch(tester);
      await press(tester, 'Save and continue');
      expect(find.textContaining('Step 2 of 4'), findsOneWidget);
      await press(tester, 'Save and continue');
      expect(find.textContaining('Step 3 of 4'), findsOneWidget);
      await press(tester, 'Save and continue');
      expect(find.textContaining('Step 4 of 4'), findsOneWidget);
      await press(tester, 'Submit application');
      await press(tester, 'Submit');
      expect(find.text('Application under review'), findsOneWidget);
      expect(find.text('Refresh agenda'), findsNothing);
      expect(
        calls.where((r) => r.method == 'PATCH').length,
        greaterThanOrEqualTo(3),
      );
    },
  );
  testWidgets(
    'development deferral keeps Documents visible and submits to pending, not Home',
    (tester) async {
      await launch(tester, storage: false, deferred: true);
      await press(tester, 'Save and continue');
      expect(find.textContaining('Step 2 of 4'), findsOneWidget);
      await press(tester, 'Save and continue');
      expect(find.textContaining('Step 3 of 4'), findsOneWidget);
      expect(find.text('Upload registration'), findsOneWidget);
      await press(tester, 'Save and continue');
      expect(find.textContaining('Step 4 of 4'), findsOneWidget);
      await press(tester, 'Back');
      expect(find.textContaining('Step 3 of 4'), findsOneWidget);
      await press(tester, 'Save and continue');
      expect(
        find.textContaining('Development testing: documents are deferred.'),
        findsOneWidget,
      );
      await press(tester, 'Submit application');
      await press(tester, 'Submit');
      expect(find.text('Application under review'), findsOneWidget);
      expect(find.text('Refresh agenda'), findsNothing);
    },
  );
  testWidgets(
    'pending screen displays submitted details without editable registration or Home',
    (tester) async {
      await launch(tester, status: 'SUBMITTED');
      expect(find.text('Application under review'), findsOneWidget);
      expect(find.text('Save draft'), findsNothing);
      expect(find.text('Refresh agenda'), findsNothing);
    },
  );
  testWidgets(
    'rejection reason is shown and correction steps remain available',
    (tester) async {
      await launch(tester, status: 'REJECTED');
      expect(find.text('Application needs correction'), findsOneWidget);
      expect(
        find.text('Replace the registration certificate.'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Save draft'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Save draft'), findsOneWidget);
    },
  );
  testWidgets(
    'unconfigured storage disables upload and submission rather than fabricating success',
    (tester) async {
      await launch(tester, storage: false);
      await press(tester, 'Save and continue');
      await press(tester, 'Save and continue');
      expect(
        find.textContaining('Secure document upload is not available'),
        findsOneWidget,
      );
      await press(tester, 'Save and continue');
      await tester.scrollUntilVisible(
        find.text('Submit application'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit application'),
      );
      expect(button.onPressed, isNull);
    },
  );
  testWidgets(
    'suspension blocks all registration edits and operational workspace',
    (tester) async {
      await launch(tester, status: 'SUSPENDED');
      expect(find.text('Doctor access is blocked'), findsOneWidget);
      expect(find.text('Save draft'), findsNothing);
      expect(find.text('Refresh agenda'), findsNothing);
    },
  );
  testWidgets('server READY retains the existing Doctor workspace', (
    tester,
  ) async {
    await launch(tester, ready: true);
    expect(find.text('Refresh agenda'), findsOneWidget);
    expect(find.textContaining('Step 1 of 4'), findsNothing);
  });
  testWidgets(
    'registration load failure has retry and never exposes Doctor Home',
    (tester) async {
      await launch(tester, failLoad: true);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Refresh agenda'), findsNothing);
    },
  );
  test(
    'typed application requires configured storage and all required document kinds',
    () {
      expect(
        RegistrationApplication.fromJson(application('DRAFT')).canSubmit,
        true,
      );
      expect(
        RegistrationApplication.fromJson(
          application('DRAFT', storage: false),
        ).canSubmit,
        false,
      );
      expect(
        RegistrationApplication.fromJson(application('SUBMITTED')).canSubmit,
        false,
      );
    },
  );
}
