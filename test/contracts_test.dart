import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:pocket_doctor_doctor/core/config/app_config.dart';
import 'package:pocket_doctor_doctor/core/networking/api_client.dart';
import 'package:pocket_doctor_doctor/features/auth/auth_controller.dart';
import 'package:pocket_doctor_doctor/features/appointments/doctor_repository.dart';
import 'package:pocket_doctor_doctor/shared/models/doctor_models.dart';
import 'fixtures.dart';

http.Response ok(Map<String, dynamic> data) =>
    http.Response(jsonEncode({'data': data}), 200);
void main() {
  setUpAll(tz.initializeTimeZones);
  test(
    'API configuration requires secure explicit deployment and no URL secrets',
    () {
      expect(
        AppConfig('https://api.example.test/api/v1/').baseUrl,
        'https://api.example.test/api/v1',
      );
      expect(
        AppConfig('http://10.0.2.2:3000/api/v1', release: false).baseUrl,
        contains('10.0.2.2'),
      );
      for (final value in [
        '',
        'http://remote.test/api/v1',
        'https://user:secret@example.test/api/v1',
        'https://example.test/api/v1?token=x',
        'https://example.test/api/v1#x',
        'http://127.0.0.1/api/v1',
      ]) {
        expect(() => AppConfig(value, release: true), throwsFormatException);
      }
    },
  );
  test('bearer in headers, data unwrapped, redirects disabled', () async {
    final api = ApiClient(
      'https://example.test/api/v1',
      transport: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer opaque');
        expect(request.followRedirects, false);
        expect(request.url.query, isEmpty);
        return ok({'saved': true});
      }),
    )..setToken('opaque');
    expect(await api.request('/doctor/profile'), {'saved': true});
  });
  test('401 clears bearer and triggers private state invalidation', () async {
    var calls = 0, resets = 0;
    final api = ApiClient(
      '',
      transport: MockClient((r) async {
        if (++calls == 1) return http.Response('', 401);
        expect(r.headers['Authorization'], isNull);
        return ok({});
      }),
    )..setToken('secret');
    api.onExpired = () => resets++;
    await expectLater(api.request('/doctor/profile'), throwsException);
    await api.request('/doctor/profile');
    expect(resets, 1);
  });
  test('late responses cannot restore signed-out data', () async {
    final pending = Completer<http.Response>();
    final api = ApiClient('', transport: MockClient((_) => pending.future))
      ..setToken('a');
    final request = api.request('/doctor/appointments');
    api.setToken(null);
    pending.complete(
      ok({
        'consultations': [appointmentJson()],
      }),
    );
    await expectLater(request, throwsException);
  });
  test(
    'malformed, backend error and timeout never expose raw clinical content',
    () async {
      for (final response in [
        http.Response('private SQL secret', 500),
        http.Response('private SQL secret', 200),
        http.Response('{}', 200),
      ]) {
        final api = ApiClient('', transport: MockClient((_) async => response));
        await expectLater(
          api.request('/doctor/profile'),
          throwsA(predicate((e) => !e.toString().contains('SQL'))),
        );
      }
      final api = ApiClient(
        '',
        timeout: const Duration(milliseconds: 1),
        transport: MockClient((_) => Completer<http.Response>().future),
      );
      await expectLater(api.request('/doctor/profile'), throwsException);
    },
  );
  test('agenda preserves doctor timezone, active and completed filters', () {
    final a = Appointment.fromJson(appointmentJson(status: 'CONFIRMED'));
    expect(
      agenda(
        [a],
        'Today',
        'Asia/Kolkata',
        DateTime.parse('2026-09-08T01:00:00Z'),
      ),
      [a],
    );
    expect(
      agenda([a], 'Today', 'UTC', DateTime.parse('2026-09-08T01:00:00Z')),
      isEmpty,
    );
    expect(
      agenda(
        [a],
        'Upcoming',
        'Asia/Kolkata',
        DateTime.parse('2026-09-07T19:00:00Z'),
      ),
      [a],
    );
    expect(agenda([a], 'Completed', 'Asia/Kolkata', DateTime.now()), isEmpty);
    expect(appointmentTime(a), contains('Asia/Kolkata'));
  });
  test('lifecycle and notes affordances match the portal', () {
    expect(Appointment.fromJson(appointmentJson(status: 'CONFIRMED')).actions, [
      'start',
      'no-show',
    ]);
    expect(Appointment.fromJson(appointmentJson()).actions, ['complete']);
    expect(Appointment.fromJson(appointmentJson(demo: false)).actions, isEmpty);
    for (final status in [
      'PENDING_PAYMENT',
      'CONFIRMED',
      'CANCELLED',
      'EXPIRED',
      'NO_SHOW',
    ]) {
      expect(
        Appointment.fromJson(appointmentJson(status: status)).canEditNotes,
        false,
      );
    }
    expect(
      Appointment.fromJson(appointmentJson(status: 'COMPLETED')).canEditNotes,
      true,
    );
  });
  test(
    'timezone input preserves backend case-insensitive names and UTC offsets',
    () {
      final instant = DateTime.parse('2026-09-07T20:00:00Z');
      for (final zone in ['asia/kolkata', '+05:30', '+0530', '+05']) {
        Availability.fromJson({
          ...availabilityJson,
          'timezone': zone,
        }).validate();
        expect(localDay(instant, zone), '2026-09-08');
      }
      expect(localDay(instant, 'utc'), '2026-09-07');
      expect(localDay(instant, '-05:30'), '2026-09-07');
      expect(() => doctorLocation('+24:00'), throwsFormatException);
    },
  );
  test(
    'availability validates midnight, real dates, overlap, limits and timezone',
    () {
      expect(parseMinute('24:00'), 1440);
      expect(() => parseMinute('09:99'), throwsFormatException);
      expect(validDate('2026-02-30'), false);
      Availability.fromJson(availabilityJson).validate();
      for (final patch in <Json>[
        {'timezone': 'Invalid/Zone'},
        {'consultationMinutes': 9},
        {'bufferMinutes': 61},
        {
          'excludedDates': ['2026-02-30'],
        },
        {
          'windows': [
            {'weekday': 1, 'startMinute': 540, 'endMinute': 1020},
            {'weekday': 1, 'startMinute': 600, 'endMinute': 800},
          ],
        },
        {
          'windows': [
            {'weekday': 1, 'startMinute': 1440, 'endMinute': 1440},
          ],
        },
      ]) {
        expect(
          () =>
              Availability.fromJson({...availabilityJson, ...patch}).validate(),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'repository uses exact existing methods and payloads without patient/doctor selectors',
    () async {
      final requests = <http.Request>[];
      final repo = DoctorRepository(
        ApiClient(
          'https://example.test/api/v1',
          transport: MockClient((request) async {
            requests.add(request);
            if (request.url.path.endsWith('/profile')) {
              return ok({'doctor': doctorJson});
            }
            if (request.url.path.endsWith('/availability')) {
              return ok(availabilityJson);
            }
            if (request.url.path.endsWith('/appointments')) {
              return ok({
                'consultations': [appointmentJson()],
              });
            }
            return ok({'saved': true});
          }),
        ),
      );
      await repo.profile();
      await repo.appointments();
      await repo.availability();
      await repo.saveProfile('Updated biography', ['english']);
      await repo.saveAvailability(Availability.fromJson(availabilityJson));
      await repo.saveNotes(
        'appointment-a',
        const ConsultationNote(
          privateNote: 'private',
          summary: 'shared',
          followUpRequired: false,
          followUpDate: '2026-09-15',
          followUpNote: 'discard',
        ),
      );
      await repo.action('appointment-a', 'complete');
      expect(requests.map((r) => r.method).toList(), [
        'GET',
        'GET',
        'GET',
        'PATCH',
        'POST',
        'POST',
        'POST',
      ]);
      expect(jsonDecode(requests[5].body), {
        'privateNote': 'private',
        'summary': 'shared',
        'followUpRequired': false,
        'followUpDate': null,
        'followUpNote': '',
      });
      expect(jsonDecode(requests[6].body), {'action': 'complete'});
      expect(
        requests.every(
          (r) => !r.body.contains('patientId') && !r.body.contains('doctorId'),
        ),
        true,
      );
    },
  );
  test('OTP, backend role resolution, secure restoration and logout', () async {
    final requests = <http.Request>[];
    final store = MemoryStore();
    final api = ApiClient(
      'https://example.test/api/v1',
      transport: MockClient((r) async {
        requests.add(r);
        if (r.url.path.endsWith('/otp/request')) {
          return ok({'challengeId': 'challenge'});
        }
        if (r.url.path.endsWith('/otp/verify')) return ok({'token': 'opaque'});
        if (r.url.path.endsWith('/doctor/session')) {
          return ok({'status': 'READY', 'doctor': doctorJson});
        }
        return ok({'loggedOut': true});
      }),
    );
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(api),
        sessionStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    final auth = container.read(authProvider.notifier);
    await auth.restore();
    expect(container.read(authProvider).session, isNull);
    final challenge = await container
        .read(authRepositoryProvider)
        .requestOtp('+919876543210');
    await auth.verify(challenge.id, '123456');
    expect(container.read(authProvider).session!.ready, true);
    expect(store.token, 'opaque');
    expect(jsonDecode(requests[0].body), {
      'phone': '+919876543210',
      'context': 'DOCTOR',
    });
    expect(jsonDecode(requests[1].body), {
      'context': 'DOCTOR',
      'challengeId': 'challenge',
      'code': '123456',
    });
    await auth.restore();
    expect(container.read(authProvider).session!.ready, true);
    await auth.logout();
    expect(store.token, isNull);
    expect(container.read(authProvider).session, isNull);
  });
  test(
    'USER rejected by doctor endpoint never becomes a doctor session',
    () async {
      final store = MemoryStore();
      final api = ApiClient(
        'https://example.test/api/v1',
        transport: MockClient((r) async {
          if (r.url.path.endsWith('/otp/verify')) {
            return ok({'token': 'user-token'});
          }
          if (r.url.path.endsWith('/doctor/session')) {
            return http.Response('', 403);
          }
          return ok({});
        }),
      );
      final container = ProviderContainer(
        overrides: [
          apiProvider.overrideWithValue(api),
          sessionStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(authProvider.notifier).verify('challenge', '123456'),
        throwsException,
      );
      expect(container.read(authProvider).session, isNull);
      expect(store.token, isNull);
    },
  );
  test(
    'backend verification states are preserved without fabricating access',
    () async {
      for (final status in [
        'PENDING_VERIFICATION',
        'REJECTED',
        'SUSPENDED',
        'INACTIVE',
        'PROFILE_REQUIRED',
        'UNAVAILABLE',
      ]) {
        final store = MemoryStore()..token = 'existing';
        final api = ApiClient(
          '',
          transport: MockClient(
            (_) async => ok({'status': status, 'doctor': null}),
          ),
        );
        final container = ProviderContainer(
          overrides: [
            apiProvider.overrideWithValue(api),
            sessionStoreProvider.overrideWithValue(store),
          ],
        );
        await container.read(authProvider.notifier).restore();
        expect(container.read(authProvider).session!.status, status);
        expect(container.read(authProvider).session!.ready, false);
        container.dispose();
      }
    },
  );
  test(
    'offline resume removes prior clinical session until server revalidation',
    () async {
      var offline = false;
      final store = MemoryStore()..token = 'existing';
      final api = ApiClient(
        '',
        transport: MockClient((_) async {
          if (offline) throw http.ClientException('offline');
          return ok({'status': 'READY', 'doctor': doctorJson});
        }),
      );
      final container = ProviderContainer(
        overrides: [
          apiProvider.overrideWithValue(api),
          sessionStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authProvider.notifier).restore();
      offline = true;
      await container.read(authProvider.notifier).refresh();
      expect(container.read(authProvider).session, isNull);
      expect(container.read(authProvider).message, contains('connect'));
    },
  );
}
