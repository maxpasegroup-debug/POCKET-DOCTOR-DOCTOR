import 'package:pocket_doctor_doctor/core/storage/session_store.dart';

final doctorJson = <String, dynamic>{
  'id': 'doctor-a',
  'name': 'Doctor A',
  'qualification': 'MBBS',
  'specialty': 'General medicine',
  'biography': 'Professional introduction',
  'languages': ['english'],
  'timezone': 'Asia/Kolkata',
  'isDemo': true,
};
Map<String, dynamic> appointmentJson({
  String status = 'IN_PROGRESS',
  bool demo = true,
}) => {
  'id': 'appointment-a',
  'patientName': 'Assigned patient',
  'startsAt': '2026-09-07T20:00:00Z',
  'endsAt': '2026-09-07T20:30:00Z',
  'timezone': 'Asia/Kolkata',
  'status': status,
  'doctor': {...doctorJson, 'isDemo': demo},
  'note': {
    'privateNote': 'Private clinical text',
    'summary': 'Shared summary',
    'followUpRequired': true,
    'followUpDate': '2026-09-15',
    'followUpNote': 'Follow-up information',
  },
};
final availabilityJson = <String, dynamic>{
  'timezone': 'Asia/Kolkata',
  'consultationMinutes': 30,
  'bufferMinutes': 5,
  'acceptingAppointments': true,
  'windows': [
    {'weekday': 1, 'startMinute': 540, 'endMinute': 1020},
  ],
  'excludedDates': ['2026-09-09'],
};

class MemoryStore implements SessionStore {
  String? token;
  @override
  Future<void> clear() async {
    token = null;
  }

  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async {
    token = value;
  }
}
