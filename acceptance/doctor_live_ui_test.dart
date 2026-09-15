import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/io_client.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:pocket_doctor_doctor/app.dart';
import 'package:pocket_doctor_doctor/core/networking/api_client.dart';
import 'package:pocket_doctor_doctor/core/storage/session_store.dart';
import 'package:pocket_doctor_doctor/features/auth/auth_controller.dart';

// Only native storage is substituted in this headless harness. Every network
// request uses actual HTTP and the existing test backend; no API fixtures.
class TransientStore implements SessionStore {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global =
      null; // Disable Flutter test's fake HTTP 400 transport.
  tz.initializeTimeZones();
  Future<void> until(WidgetTester tester, Finder target) async {
    for (var i = 0; i < 150; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (target.evaluate().isNotEmpty) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
    }
    fail('Expected screen did not load; screen/OTP contents withheld.');
  }

  Finder field(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(TextFormField));
  for (var index = 1; index <= 2; index++) {
    testWidgets(
      'real HTTP Doctor ${index == 1 ? 'A' : 'B'} UI login, profile, availability, remount and logout',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2200);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = TransientStore();
        final clients = <IOClient>[];
        addTearDown(() {
          for (final client in clients) {
            client.close();
          }
        });
        Future<void> mount() async {
          final client = IOClient(HttpClient());
          clients.add(client);
          final api = ApiClient(
            'http://127.0.0.1:3018/api/v1',
            transport: client,
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
        }

        try {
          await mount();
          await until(tester, find.text('Send verification code'));
          await tester.enterText(
            find.byType(TextFormField),
            '+91999991800$index',
          );
          await tester.tap(find.text('Send verification code'));
          await until(tester, find.textContaining('Local development code:'));
          final codeWidget = tester.widget<Text>(
            find.textContaining('Local development code:'),
          );
          final code = RegExp(r'\d{6}').firstMatch(codeWidget.data!)!.group(0)!;
          await tester.enterText(find.byType(TextFormField), code);
          await tester.tap(find.text('Verify & continue'));
          await until(tester, find.text('Home'));
          await until(tester, find.text('Refresh agenda'));
          await tester.tap(find.text('Profile'));
          await until(tester, find.text('Save profile'));
          expect(
            find.text('DEMO D-ENVIRONMENT Doctor ${index == 1 ? 'A' : 'B'}'),
            findsOneWidget,
          );
          final introduction =
              'DEMO headless Flutter live persistence Doctor $index';
          await tester.enterText(
            field('Professional introduction'),
            introduction,
          );
          await tester.enterText(field('Languages'), 'english, hindi');
          await tester.ensureVisible(find.text('Save profile'));
          await tester.tap(find.text('Save profile'));
          await until(tester, find.text('Profile saved.'));
          await tester.tap(find.text('Availability'));
          await until(tester, find.text('Timezone'));
          await tester.scrollUntilVisible(
            find.text('Save availability'),
            500,
            scrollable: find.byType(Scrollable).first,
            maxScrolls: 40,
          );
          await tester.ensureVisible(find.text('Save availability'));
          await tester.tap(find.text('Save availability'));
          await until(tester, find.text('Availability saved.'));
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          await mount();
          await until(tester, find.text('Home'));
          await tester.tap(find.text('Profile'));
          await until(tester, find.text('Save profile'));
          final bio = tester.widget<TextFormField>(
            field('Professional introduction'),
          );
          expect(bio.controller!.text, introduction);
          await tester.tap(find.byTooltip('Log out'));
          await until(tester, find.text('Send verification code'));
          expect(store.token, isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          for (final client in clients) {
            client.close();
          }
          await tester.pump(const Duration(seconds: 16));
        }
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }
}
