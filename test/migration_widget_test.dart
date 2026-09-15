import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:pocket_doctor_doctor/app.dart';
import 'package:pocket_doctor_doctor/core/networking/api_client.dart';
import 'package:pocket_doctor_doctor/features/auth/auth_controller.dart';
import 'fixtures.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  Future<List<http.Request>> launch(
    WidgetTester tester, {
    bool authenticated = true,
    String status = 'READY',
    bool empty = false,
    bool failRefresh = false,
  }) async {
    final requests = <http.Request>[];
    var currentDoctor = {...doctorJson};
    final currentAppointment = appointmentJson();
    var appointmentReads = 0;
    final store = MemoryStore()..token = authenticated ? 'opaque' : null;
    final api = ApiClient(
      'https://example.test/api/v1',
      transport: MockClient((r) async {
        requests.add(r);
        final path = r.url.path;
        if (path == '/api/v1/doctor/appointments' &&
            ++appointmentReads > 1 &&
            failRefresh) {
          return http.Response('', 503);
        }
        if (path == '/api/v1/doctor/profile' && r.method == 'PATCH') {
          currentDoctor = {
            ...currentDoctor,
            ...jsonDecode(r.body) as Map<String, dynamic>,
          };
        }
        if (path.endsWith('/notes') && r.method == 'POST') {
          currentAppointment['note'] = jsonDecode(r.body);
        }
        final data = switch (path) {
          '/api/v1/doctor/session' => {
            'status': status,
            'doctor': status == 'READY' ? currentDoctor : null,
          },
          '/api/v1/doctor/profile' => {'doctor': currentDoctor},
          '/api/v1/doctor/availability' => availabilityJson,
          '/api/v1/doctor/appointments' => {
            'consultations': empty ? [] : [currentAppointment],
          },
          '/api/v1/auth/otp/request' => {'challengeId': 'challenge'},
          '/api/v1/auth/otp/verify' => {'token': 'opaque'},
          _ => {'saved': true},
        };
        return http.Response(jsonEncode({'data': data}), 200);
      }),
    );
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
    return requests;
  }

  testWidgets(
    'Android back returns secondary tabs to Home and closes appointment first',
    (tester) async {
      await launch(tester);
      for (final label in ['Profile', 'Availability']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Refresh agenda'), findsOneWidget);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          0,
        );
      }
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assigned patient'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Refresh agenda'), findsOneWidget);
      expect(find.text('Private clinical text'), findsNothing);
    },
  );
  testWidgets('OTP validates phone and six digits, then reaches Doctor Home', (
    tester,
  ) async {
    final requests = await launch(tester, authenticated: false);
    await tester.tap(find.text('Send verification code'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a valid 10-digit mobile number.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), '+91 98765 43210');
    expect(tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text, '9876543210');
    await tester.tap(find.text('Send verification code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '123');
    await tester.tap(find.text('Verify & continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter all six digits.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Verify & continue'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(jsonDecode(requests.firstWhere((r) => r.url.path.endsWith('/otp/request')).body)['phone'], '+919876543210');
    expect(requests.where((r) => r.url.path.endsWith('/otp/verify')).length, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('agenda shows empty state and supports retry', (tester) async {
    await launch(tester, empty: true);
    expect(find.text('A little breathing room.'), findsOneWidget);
    await tester.tap(find.text('Refresh agenda'));
    await tester.pumpAndSettle();
    expect(find.text('A little breathing room.'), findsOneWidget);
  });
  testWidgets(
    'notes remain distinct and unchecked follow-up sends null/empty',
    (tester) async {
      final requests = await launch(tester);
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assigned patient'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Private doctor note'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Private clinical text'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Follow-up required'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save notes'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save notes'));
      await tester.pumpAndSettle();
      final request = requests.lastWhere((r) => r.url.path.endsWith('/notes'));
      expect(jsonDecode(request.body), {
        'privateNote': 'Private clinical text',
        'summary': 'Shared summary',
        'followUpRequired': false,
        'followUpDate': null,
        'followUpNote': '',
      });
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assigned patient'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Follow-up required'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<Switch>(find.byType(Switch)).value, false);
    },
  );
  testWidgets('profile keeps credentials read-only and uses existing PATCH', (
    tester,
  ) async {
    final requests = await launch(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('MBBS · General medicine'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'Updated biography',
    );
    await tester.scrollUntilVisible(
      find.text('Save profile'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    final request = requests.lastWhere((r) => r.method == 'PATCH');
    expect(jsonDecode(request.body), {
      'biography': 'Updated biography',
      'languages': ['english'],
    });
    expect(find.text('Profile saved.'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Updated biography'), findsOneWidget);
  });
  testWidgets(
    'availability retains server fields and saves existing contract',
    (tester) async {
      final requests = await launch(tester);
      await tester.tap(find.text('Availability'));
      await tester.pumpAndSettle();
      expect(find.text('Asia/Kolkata'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Save availability'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save availability'));
      await tester.pumpAndSettle();
      final request = requests.lastWhere((r) => r.method == 'POST');
      expect(jsonDecode(request.body), availabilityJson);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed pull-to-refresh shows retry without an unhandled exception',
    (tester) async {
      await launch(tester, empty: true, failRefresh: true);
      final refresh = tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();
      await refresh;
      expect(find.text('Retry'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('backend rejection state has no doctor workspace', (
    tester,
  ) async {
    await launch(tester, status: 'REJECTED');
    expect(find.text('REJECTED'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Check status'), findsOneWidget);
  });
  testWidgets(
    'logout from appointment removes private content and navigation',
    (tester) async {
      await launch(tester);
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assigned patient'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Log out'));
      await tester.pumpAndSettle();
      expect(find.text('Assigned patient'), findsNothing);
      expect(find.text('Private clinical text'), findsNothing);
      expect(find.text('Send verification code'), findsOneWidget);
    },
  );
  testWidgets('320 pixel mobile layout does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await launch(tester);
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Availability'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
