import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/networking/api_client.dart';
import '../../shared/models/doctor_models.dart';
import '../auth/auth_controller.dart';

class DoctorRepository {
  DoctorRepository(this.api);
  final ApiClient api;
  Future<Doctor> profile() async =>
      Doctor.fromJson((await api.request('/doctor/profile'))['doctor'] as Json);
  Future<Doctor> saveProfile(String biography, List<String> languages) async =>
      Doctor.fromJson(
        (await api.request(
              '/doctor/profile',
              method: 'PATCH',
              body: {'biography': biography, 'languages': languages},
            ))['doctor']
            as Json,
      );
  Future<List<Appointment>> appointments() async =>
      ((await api.request('/doctor/appointments'))['consultations'] as List)
          .map((a) => Appointment.fromJson(a as Json))
          .toList();
  Future<Availability> availability() async =>
      Availability.fromJson(await api.request('/doctor/availability'));
  Future<Availability> saveAvailability(Availability value) async {
    value.validate();
    return Availability.fromJson(
      await api.request(
        '/doctor/availability',
        method: 'POST',
        body: value.toJson(),
      ),
    );
  }

  Future<void> saveNotes(String appointmentId, ConsultationNote note) async {
    await api.request(
      '/doctor/consultations/${Uri.encodeComponent(appointmentId)}/notes',
      method: 'POST',
      body: note.toJson(),
    );
  }

  Future<void> action(String appointmentId, String action) async {
    await api.request(
      '/doctor/consultations/${Uri.encodeComponent(appointmentId)}/action',
      method: 'POST',
      body: {'action': action},
    );
  }
}

final doctorRepositoryProvider = Provider(
  (ref) => DoctorRepository(ref.watch(apiProvider)),
);
void requireSession(Ref ref) {
  final auth = ref.watch(authProvider);
  if (auth.loading || !(auth.session?.ready ?? false)) {
    throw StateError('Doctor session required.');
  }
}

final profileProvider = FutureProvider.autoDispose<Doctor>((ref) {
  requireSession(ref);
  return ref.watch(doctorRepositoryProvider).profile();
});
final appointmentsProvider = FutureProvider.autoDispose<List<Appointment>>((
  ref,
) {
  requireSession(ref);
  return ref.watch(doctorRepositoryProvider).appointments();
});
final availabilityProvider = FutureProvider.autoDispose<Availability>((ref) {
  requireSession(ref);
  return ref.watch(doctorRepositoryProvider).availability();
});
