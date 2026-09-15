import '../../core/networking/api_client.dart';
import '../../shared/models/doctor_models.dart';

class DoctorSession {
  const DoctorSession(
    this.status,
    this.doctor, {
    this.registrationRequired = false,
  });
  final bool registrationRequired;
  final String status;
  final Doctor? doctor;
  bool get ready => status == 'READY' && doctor != null;
}

class OtpChallenge {
  const OtpChallenge(this.id, this.developmentCode);
  final String id;
  final String? developmentCode;
}

class AuthRepository {
  AuthRepository(this.api);
  final ApiClient api;
  Future<OtpChallenge> requestOtp(
    String phone, {
    bool registration = false,
  }) async {
    final json = await api.request(
      registration ? '/doctor/registration/otp/request' : '/auth/otp/request',
      method: 'POST',
      body: {'phone': phone, if (!registration) 'context': 'DOCTOR'},
    );
    return OtpChallenge(
      json['challengeId'] as String,
      json['developmentCode'] as String?,
    );
  }

  Future<String> verifyOtp(
    String challengeId,
    String code, {
    bool registration = false,
  }) async =>
      (await api.request(
            registration
                ? '/doctor/registration/otp/verify'
                : '/auth/otp/verify',
            method: 'POST',
            body: {
              'challengeId': challengeId,
              'code': code,
              if (!registration) 'context': 'DOCTOR',
            },
          ))['token']
          as String;
  Future<DoctorSession> session() async {
    // This endpoint authorizes DOCTOR before returning verification state.
    final json = await api.request('/doctor/session');
    return DoctorSession(
      json['status'] as String,
      json['doctor'] == null ? null : Doctor.fromJson(json['doctor'] as Json),
      registrationRequired:
          (json['registration'] as Json?)?['required'] == true,
    );
  }

  Future<void> logout() async {
    await api.request('/auth/logout', method: 'POST');
  }
}
