import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocket_doctor_doctor/app.dart';
import 'package:pocket_doctor_doctor/core/networking/api_client.dart';
import 'package:pocket_doctor_doctor/features/auth/auth_controller.dart';
import 'package:pocket_doctor_doctor/features/registration/registration_screen.dart';
import 'fixtures.dart';
import 'registration_test.dart' show application;

void main() {
  for (final scenario in [
    'select five documents',
    'cancel picker',
    'expired session',
  ]) {
    testWidgets('gallery return preserves registration: $scenario', (
      tester,
    ) async {
      var data = application('DRAFT');
      data['documents'] = <Map<String, dynamic>>[];
      var sessionReads = 0;
      var uploads = 0;
      Completer<http.Response>? sessionReply;
      Completer<List<String>?>? selection;
      final directory = Directory.systemTemp.createTempSync(
        'doctor-picker-test-',
      );
      final file = File('${directory.path}/selected.png')
        ..writeAsBytesSync(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aL1sAAAAASUVORK5CYII=',
          ),
        );
      addTearDown(() => directory.deleteSync(recursive: true));
      const channel = MethodChannel('plugins.flutter.io/file_selector');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        expect(call.method, 'openFile');
        selection = Completer<List<String>?>();
        return selection!.future;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      Map<String, dynamic> session() => {
        'status': 'PENDING_VERIFICATION',
        'doctor': null,
        'registration': {'required': true, 'status': 'DRAFT'},
      };
      final api = ApiClient(
        'https://example.test/api/v1',
        transport: MockClient((request) async {
          if (request.url.path.endsWith('/doctor/session')) {
            sessionReads++;
            if (sessionReads > 1) {
              sessionReply = Completer<http.Response>();
              return sessionReply!.future;
            }
            return http.Response(jsonEncode({'data': session()}), 200);
          }
          if (request.url.path.endsWith('/auth/logout')) {
            return http.Response('{"data":{}}', 200);
          }
          if (request.method == 'PATCH') {
            data = {...data, 'profile': jsonDecode(request.body)};
          }
          if (request.url.path.endsWith('/documents') &&
              request.method == 'POST') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            uploads++;
            (data['documents'] as List).add({
              'id': 'doc-$uploads',
              'kind': body['kind'],
              'fileName': body['fileName'],
              'size': file.lengthSync(),
            });
          }
          return http.Response(jsonEncode({'data': data}), 200);
        }),
      );
      addTearDown(api.close);
      final store = MemoryStore()..token = 'test-session';
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
      Future<void> press(String label) async {
        final target = find.text(label);
        await tester.scrollUntilVisible(
          target,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
      }

      await press('Save and continue');
      await press('Save and continue');
      expect(find.textContaining('Step 3 of 4'), findsOneWidget);
      final originalForm = tester.state(find.byType(RegistrationForm));
      final kinds = scenario == 'select five documents'
          ? [
              'qualification',
              'registration',
              'identity',
              'profile photo',
              'additional',
            ]
          : ['qualification'];
      for (final kind in kinds) {
        final uploadsBeforeSelection = uploads;
        selection = null;
        await press('Upload $kind');
        expect(selection, isNotNull);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        // Privacy cover must hide, not destroy, the in-progress form.
        expect(
          find.byType(RegistrationForm, skipOffstage: false),
          findsOneWidget,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(sessionReply, isNotNull);
        expect(
          tester.state(find.byType(RegistrationForm, skipOffstage: false)),
          same(originalForm),
        );
        expect(find.bySemanticsLabel('Checking your session'), findsOneWidget);
        sessionReply!.complete(
          scenario == 'expired session'
              ? http.Response('{"error":{"code":"UNAUTHENTICATED"}}', 401)
              : http.Response(jsonEncode({'data': session()}), 200),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          selection!.complete(
            scenario == 'select five documents' ? [file.path] : null,
          );
          await Future<void>.delayed(const Duration(milliseconds: 60));
        });
        // Native file reads finish outside the widget tester's fake clock.
        if (scenario == 'select five documents') {
          for (
            var attempt = 0;
            attempt < 100 && uploads == uploadsBeforeSelection;
            attempt++
          ) {
            await tester.pump();
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 50)),
            );
          }
          expect(uploads, uploadsBeforeSelection + 1);
        }
        await tester.pumpAndSettle();
        if (scenario == 'expired session') {
          expect(find.byType(RegistrationForm), findsNothing);
          expect(find.text('Register as Doctor'), findsOneWidget);
          expect(store.token, isNull);
        } else {
          expect(
            tester.state(find.byType(RegistrationForm)),
            same(originalForm),
          );
          expect(find.textContaining('Step 3 of 4'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
      expect(uploads, scenario == 'select five documents' ? 5 : 0);
      expect(sessionReads, kinds.length + 1);
    });
  }
}
