import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/doctor_models.dart';
import '../../shared/widgets/workspace_widgets.dart';
import '../appointments/doctor_repository.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({required this.onOpen, super.key});
  final ValueChanged<String> onOpen;
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String filter = 'Today';
  @override
  Widget build(BuildContext context) => AsyncContent(
    value: ref.watch(profileProvider),
    retry: () => ref.invalidate(profileProvider),
    builder: (doctor) => AsyncContent(
      value: ref.watch(appointmentsProvider),
      retry: () => ref.invalidate(appointmentsProvider),
      builder: (items) {
        final list = agenda(items, filter, doctor.timezone, DateTime.now());
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(appointmentsProvider);
            try {
              await ref.read(appointmentsProvider.future);
            } catch (_) {
              // AsyncContent presents the error and retry control.
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'A little more care, one conversation at a time.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(doctor.name),
              if (doctor.isDemo)
                const Notice(
                  'DEMO workspace · Sample account and appointments. No real consultation takes place.',
                ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: [
                  for (final name in ['Today', 'Upcoming', 'Completed', 'All'])
                    ChoiceChip(
                      label: Text(name),
                      selected: filter == name,
                      onSelected: (_) => setState(() => filter = name),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Times shown in ${doctor.timezone}. Latest 100 appointments.',
              ),
              const SizedBox(height: 16),
              if (list.isEmpty) ...[
                Text(
                  filter == 'Today'
                      ? 'A little breathing room.'
                      : 'No appointments here yet.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  filter == 'Today'
                      ? 'Your appointments for today will appear here. Review your upcoming schedule or update your availability.'
                      : 'Appointments will appear as bookings are confirmed and completed.',
                ),
              ],
              for (final a in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(a.patientName),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${appointmentTime(a)}\n${a.status.replaceAll('_', ' ')}',
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => widget.onOpen(a.id),
                    ),
                  ),
                ),
              OutlinedButton(
                onPressed: () => ref.invalidate(appointmentsProvider),
                child: const Text('Refresh agenda'),
              ),
            ],
          ),
        );
      },
    ),
  );
}
