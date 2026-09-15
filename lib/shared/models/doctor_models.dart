import 'package:timezone/timezone.dart' as tz;

typedef Json = Map<String, dynamic>;

// Match Intl's case-insensitive IANA names and numeric UTC offsets without
// generating slots or changing the timezone value sent to the backend.
tz.Location doctorLocation(String name) {
  final lower = name.toLowerCase();
  for (final entry in tz.timeZoneDatabase.locations.entries) {
    if (entry.key.toLowerCase() == lower) return entry.value;
  }
  final offset = RegExp(
    r'^([+-])([01]\d|2[0-3])(?::?([0-5]\d))?$',
  ).firstMatch(name);
  if (offset != null) {
    final minutes =
        (int.parse(offset[2]!) * 60 + int.parse(offset[3] ?? '0')) *
        (offset[1] == '-' ? -1 : 1);
    return tz.Location(name, [], [], [
      tz.TimeZone(Duration(minutes: minutes), isDst: false, abbreviation: name),
    ]);
  }
  throw const FormatException(
    'Enter a valid timezone, for example Asia/Kolkata.',
  );
}

class Doctor {
  Doctor.fromJson(Json json)
    : id = json['id'] as String,
      name = json['name'] as String,
      qualification = json['qualification'] as String,
      specialty = json['specialty'] as String,
      biography = json['biography'] as String,
      languages = List<String>.from(json['languages'] as List),
      timezone = json['timezone'] as String,
      isDemo = json['isDemo'] as bool;
  final String id, name, qualification, specialty, biography, timezone;
  final List<String> languages;
  final bool isDemo;
}

class ConsultationNote {
  const ConsultationNote({
    this.privateNote = '',
    this.summary = '',
    this.followUpRequired = false,
    this.followUpDate,
    this.followUpNote = '',
  });
  factory ConsultationNote.fromJson(Json json) => ConsultationNote(
    privateNote: json['privateNote'] as String,
    summary: json['summary'] as String,
    followUpRequired: json['followUpRequired'] as bool,
    followUpDate: json['followUpDate'] as String?,
    followUpNote: json['followUpNote'] as String,
  );
  final String privateNote, summary, followUpNote;
  final bool followUpRequired;
  final String? followUpDate;
  Json toJson() => {
    'privateNote': privateNote,
    'summary': summary,
    'followUpRequired': followUpRequired,
    'followUpDate': followUpRequired ? followUpDate : null,
    'followUpNote': followUpRequired ? followUpNote : '',
  };
}

class Appointment {
  Appointment.fromJson(Json json)
    : id = json['id'] as String,
      patientName = json['patientName'] as String,
      startsAt = DateTime.parse(json['startsAt'] as String),
      endsAt = DateTime.parse(json['endsAt'] as String),
      timezone = json['timezone'] as String,
      status = json['status'] as String,
      doctor = Doctor.fromJson(json['doctor'] as Json),
      note = json['note'] == null
          ? null
          : ConsultationNote.fromJson(json['note'] as Json);
  final String id, patientName, timezone, status;
  final DateTime startsAt, endsAt;
  final Doctor doctor;
  final ConsultationNote? note;
  bool get canEditNotes => ['IN_PROGRESS', 'COMPLETED'].contains(status);
  List<String> get actions => !doctor.isDemo
      ? []
      : switch (status) {
          'CONFIRMED' => ['start', 'no-show'],
          'IN_PROGRESS' => ['complete'],
          _ => [],
        };
}

String localDay(DateTime date, String zone) {
  final local = tz.TZDateTime.from(date, doctorLocation(zone));
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String appointmentTime(Appointment a) {
  final date = tz.TZDateTime.from(a.startsAt, doctorLocation(a.timezone));
  return '${localDay(a.startsAt, a.timezone)} · ${clockMinute(date.hour * 60 + date.minute)} ${date.timeZoneName} (${a.timezone})';
}

List<Appointment> agenda(
  List<Appointment> items,
  String filter,
  String zone,
  DateTime now,
) =>
    items
        .where(
          (a) => switch (filter) {
            'Completed' => a.status == 'COMPLETED',
            'Today' => localDay(a.startsAt, zone) == localDay(now, zone),
            'Upcoming' =>
              [
                    'CONFIRMED',
                    'IN_PROGRESS',
                    'PENDING_PAYMENT',
                  ].contains(a.status) &&
                  a.endsAt.isAfter(now),
            _ => true,
          },
        )
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

class WorkingWindow {
  const WorkingWindow(this.weekday, this.startMinute, this.endMinute);
  factory WorkingWindow.fromJson(Json j) => WorkingWindow(
    j['weekday'] as int,
    j['startMinute'] as int,
    j['endMinute'] as int,
  );
  final int weekday, startMinute, endMinute;
  Json toJson() => {
    'weekday': weekday,
    'startMinute': startMinute,
    'endMinute': endMinute,
  };
}

class Availability {
  const Availability({
    required this.timezone,
    required this.consultationMinutes,
    required this.bufferMinutes,
    required this.acceptingAppointments,
    required this.windows,
    required this.excludedDates,
  });
  factory Availability.fromJson(Json j) => Availability(
    timezone: j['timezone'] as String,
    consultationMinutes: j['consultationMinutes'] as int,
    bufferMinutes: j['bufferMinutes'] as int,
    acceptingAppointments: j['acceptingAppointments'] as bool,
    windows: (j['windows'] as List)
        .map((w) => WorkingWindow.fromJson(w as Json))
        .toList(),
    excludedDates: List<String>.from(j['excludedDates'] as List),
  );
  final String timezone;
  final int consultationMinutes, bufferMinutes;
  final bool acceptingAppointments;
  final List<WorkingWindow> windows;
  final List<String> excludedDates;
  Json toJson() => {
    'timezone': timezone,
    'consultationMinutes': consultationMinutes,
    'bufferMinutes': bufferMinutes,
    'acceptingAppointments': acceptingAppointments,
    'windows': windows.map((w) => w.toJson()).toList(),
    'excludedDates': excludedDates.toSet().toList(),
  };
  void validate() {
    try {
      doctorLocation(timezone);
    } catch (_) {
      throw const FormatException(
        'Enter a valid timezone, for example Asia/Kolkata.',
      );
    }
    if (consultationMinutes < 10 ||
        consultationMinutes > 120 ||
        bufferMinutes < 0 ||
        bufferMinutes > 60) {
      throw const FormatException(
        'Use a consultation length of 10–120 minutes and a buffer of 0–60 minutes.',
      );
    }
    if (windows.length > 28 || excludedDates.toSet().length > 120) {
      throw const FormatException(
        'Use at most 28 windows and 120 unavailable dates.',
      );
    }
    for (var i = 0; i < windows.length; i++) {
      final w = windows[i];
      if (w.weekday < 1 ||
          w.weekday > 7 ||
          w.startMinute < 0 ||
          w.startMinute >= 1440 ||
          w.endMinute > 1440 ||
          w.endMinute - w.startMinute < consultationMinutes ||
          windows
              .take(i)
              .any(
                (other) =>
                    other.weekday == w.weekday &&
                    other.startMinute < w.endMinute &&
                    other.endMinute > w.startMinute,
              )) {
        throw const FormatException(
          'Working windows must fit a consultation and must not overlap.',
        );
      }
    }
    if (excludedDates.any((date) => !validDate(date))) {
      throw const FormatException(
        'Enter valid unavailable dates as YYYY-MM-DD.',
      );
    }
  }
}

bool validDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final parsed = DateTime.tryParse('${value}T00:00:00Z');
  return parsed != null && parsed.toIso8601String().substring(0, 10) == value;
}

int parseMinute(String value) {
  if (!RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(value) &&
      value != '24:00') {
    throw const FormatException(
      'Enter working times as HH:MM, for example 09:00 or 24:00.',
    );
  }
  final parts = value.split(':').map(int.parse).toList();
  return parts[0] * 60 + parts[1];
}

String clockMinute(int value) =>
    '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
