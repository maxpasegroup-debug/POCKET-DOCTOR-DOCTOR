import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/doctor_models.dart';
import '../../shared/widgets/workspace_widgets.dart';
import '../appointments/doctor_repository.dart';

class ConsultationScreen extends ConsumerWidget {
  const ConsultationScreen({required this.id, required this.onBack, super.key});
  final String id;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncContent(
    value: ref.watch(appointmentsProvider),
    retry: () => ref.invalidate(appointmentsProvider),
    builder: (items) {
      final matches = items.where((a) => a.id == id);
      if (matches.isEmpty) {
        return FormPage(
          children: [
            const Notice(
              'This appointment is no longer in your assigned agenda.',
            ),
            TextButton(onPressed: onBack, child: const Text('Back to agenda')),
          ],
        );
      }
      return ConsultationForm(
        key: ValueKey('${id}_${matches.first.status}'),
        appointment: matches.first,
        onBack: onBack,
      );
    },
  );
}

class ConsultationForm extends ConsumerStatefulWidget {
  const ConsultationForm({
    required this.appointment,
    required this.onBack,
    super.key,
  });
  final Appointment appointment;
  final VoidCallback onBack;
  @override
  ConsumerState<ConsultationForm> createState() => _ConsultationFormState();
}

class _ConsultationFormState extends ConsumerState<ConsultationForm> {
  late final privateNote = TextEditingController(
    text: widget.appointment.note?.privateNote ?? '',
  );
  late final summary = TextEditingController(
    text: widget.appointment.note?.summary ?? '',
  );
  late final date = TextEditingController(
    text: widget.appointment.note?.followUpDate ?? '',
  );
  late final followNote = TextEditingController(
    text: widget.appointment.note?.followUpNote ?? '',
  );
  late bool follow = widget.appointment.note?.followUpRequired ?? false;
  bool busy = false, failed = false;
  String? message;
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    for (final c in [privateNote, summary, date, followNote]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> perform(
    Future<void> Function() task, {
    bool refresh = false,
  }) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await task();
      if (!mounted) return;
      if (refresh) {
        ref.invalidate(appointmentsProvider);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notes saved.')));
        // Refresh the shared agenda too, including Android back navigation.
        ref.invalidate(appointmentsProvider);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          failed = true;
          message = friendlyError(error);
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    await perform(
      () => ref
          .read(doctorRepositoryProvider)
          .saveNotes(
            widget.appointment.id,
            ConsultationNote(
              privateNote: privateNote.text,
              summary: summary.text,
              followUpRequired: follow,
              followUpDate: follow && date.text.isNotEmpty ? date.text : null,
              followUpNote: follow ? followNote.text : '',
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    return Form(
      key: form,
      child: FormPage(
        children: [
          TextButton(
            onPressed: busy
                ? null
                : () {
                    ref.invalidate(appointmentsProvider);
                    widget.onBack();
                  },
            child: const Text('Back to agenda'),
          ),
          Text(a.patientName, style: Theme.of(context).textTheme.headlineSmall),
          Text(appointmentTime(a)),
          Text(a.status.replaceAll('_', ' ')),
          const Notice(
            'Consultation connection is not available yet. Video provider integration is pending. This is not an emergency service.',
          ),
          for (final action in a.actions)
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () => perform(
                      () => ref
                          .read(doctorRepositoryProvider)
                          .action(a.id, action),
                      refresh: true,
                    ),
              child: Text('DEMO: $action'),
            ),
          if (message != null) Notice(message!, error: failed),
          if (!a.canEditNotes)
            const Notice('Notes are available during or after a consultation.')
          else ...[
            Text(
              'Consultation notes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Keep private notes separate from the summary shared with the patient after completion.',
            ),
            TextFormField(
              controller: privateNote,
              enabled: !busy,
              minLines: 3,
              maxLines: 10,
              maxLength: 10000,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Private doctor note',
              ),
            ),
            TextFormField(
              controller: summary,
              enabled: !busy,
              minLines: 3,
              maxLines: 8,
              maxLength: 5000,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Patient-visible summary',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Follow-up required'),
              value: follow,
              onChanged: busy
                  ? null
                  : (value) => setState(() => follow = value),
            ),
            TextFormField(
              controller: date,
              enabled: follow && !busy,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Follow-up date (optional)',
                hintText: 'YYYY-MM-DD',
              ),
              validator: (value) =>
                  !follow || value!.isEmpty || validDate(value)
                  ? null
                  : 'Enter a valid date as YYYY-MM-DD.',
            ),
            TextFormField(
              controller: followNote,
              enabled: follow && !busy,
              minLines: 2,
              maxLines: 6,
              maxLength: 2000,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Patient-visible follow-up note',
              ),
            ),
            FilledButton(
              onPressed: busy ? null : save,
              child: Text(busy ? 'Saving…' : 'Save notes'),
            ),
          ],
          OutlinedButton(
            onPressed: busy ? null : () => ref.invalidate(appointmentsProvider),
            child: const Text('Refresh appointment'),
          ),
        ],
      ),
    );
  }
}
