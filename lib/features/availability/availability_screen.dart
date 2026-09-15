import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/doctor_models.dart';
import '../../shared/widgets/workspace_widgets.dart';
import '../appointments/doctor_repository.dart';

class AvailabilityScreen extends ConsumerWidget {
  const AvailabilityScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncContent(
    value: ref.watch(availabilityProvider),
    retry: () => ref.invalidate(availabilityProvider),
    builder: (value) => AvailabilityForm(value: value),
  );
}

class WindowControls {
  WindowControls(WorkingWindow value)
    : weekday = value.weekday,
      start = TextEditingController(text: clockMinute(value.startMinute)),
      end = TextEditingController(text: clockMinute(value.endMinute));
  int weekday;
  final TextEditingController start, end;
  void dispose() {
    start.dispose();
    end.dispose();
  }

  WorkingWindow value() => WorkingWindow(
    weekday,
    parseMinute(start.text.trim()),
    parseMinute(end.text.trim()),
  );
}

class AvailabilityForm extends ConsumerStatefulWidget {
  const AvailabilityForm({required this.value, super.key});
  final Availability value;
  @override
  ConsumerState<AvailabilityForm> createState() => _AvailabilityFormState();
}

class _AvailabilityFormState extends ConsumerState<AvailabilityForm> {
  late final zone = TextEditingController(text: widget.value.timezone);
  late final duration = TextEditingController(
    text: '${widget.value.consultationMinutes}',
  );
  late final buffer = TextEditingController(
    text: '${widget.value.bufferMinutes}',
  );
  late final dates = TextEditingController(
    text: widget.value.excludedDates.join(', '),
  );
  late final windows = widget.value.windows.map(WindowControls.new).toList();
  late bool accepting = widget.value.acceptingAppointments;
  bool busy = false, failed = false;
  String? message;
  @override
  void dispose() {
    for (final c in [zone, duration, buffer, dates]) {
      c.dispose();
    }
    for (final row in windows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final value = Availability(
        timezone: zone.text.trim(),
        consultationMinutes: int.tryParse(duration.text) ?? -1,
        bufferMinutes: int.tryParse(buffer.text) ?? -1,
        acceptingAppointments: accepting,
        windows: windows.map((row) => row.value()).toList(),
        excludedDates: dates.text
            .split(',')
            .map((v) => v.trim())
            .where((v) => v.isNotEmpty)
            .toList(),
      );
      await ref.read(doctorRepositoryProvider).saveAvailability(value);
      ref.invalidate(profileProvider);
      if (mounted) {
        setState(() {
          message = 'Availability saved.';
          failed = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          message = friendlyError(error);
          failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FormPage(
    children: [
      Text(
        'Make room for care',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const Text(
        'Set recurring working windows in your timezone. Separate windows leave a break. Existing appointments retain their booked time.',
      ),
      TextField(
        controller: zone,
        enabled: !busy,
        decoration: const InputDecoration(
          labelText: 'Timezone',
          hintText: 'Asia/Kolkata',
        ),
      ),
      TextField(
        controller: duration,
        enabled: !busy,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Consultation length (minutes)',
          helperText: '10–120 minutes',
        ),
      ),
      TextField(
        controller: buffer,
        enabled: !busy,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Buffer between appointments',
          helperText: '0–60 minutes',
        ),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Accepting appointments'),
        value: accepting,
        onChanged: busy ? null : (value) => setState(() => accepting = value),
      ),
      Text('Weekly windows', style: Theme.of(context).textTheme.titleLarge),
      for (final row in windows)
        Card(
          key: ObjectKey(row),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: row.weekday,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Working day'),
                  items: [
                    for (var i = 0; i < 7; i++)
                      DropdownMenuItem(
                        value: i + 1,
                        child: Text(
                          const [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                            'Sunday',
                          ][i],
                        ),
                      ),
                  ],
                  onChanged: busy
                      ? null
                      : (value) => setState(() => row.weekday = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: row.start,
                  enabled: !busy,
                  decoration: const InputDecoration(labelText: 'From (HH:MM)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: row.end,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'Until (HH:MM)',
                    helperText: '24:00 is midnight at the end of the day',
                  ),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          setState(() => windows.remove(row));
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => row.dispose(),
                          );
                        },
                  child: const Text('Remove window'),
                ),
              ],
            ),
          ),
        ),
      OutlinedButton(
        onPressed: busy || windows.length >= 28
            ? null
            : () => setState(
                () => windows.add(
                  WindowControls(const WorkingWindow(1, 540, 1020)),
                ),
              ),
        child: const Text('Add working window'),
      ),
      TextField(
        controller: dates,
        enabled: !busy,
        minLines: 2,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: 'Unavailable dates',
          helperText: 'YYYY-MM-DD, separated with commas',
        ),
      ),
      if (message != null) Notice(message!, error: failed),
      FilledButton(
        onPressed: busy ? null : save,
        child: Text(busy ? 'Saving…' : 'Save availability'),
      ),
    ],
  );
}
