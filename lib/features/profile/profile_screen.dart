import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/doctor_models.dart';
import '../../shared/widgets/workspace_widgets.dart';
import '../appointments/doctor_repository.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncContent(
    value: ref.watch(profileProvider),
    retry: () => ref.invalidate(profileProvider),
    builder: (doctor) => ProfileForm(doctor: doctor),
  );
}

class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({required this.doctor, super.key});
  final Doctor doctor;
  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  late final biography = TextEditingController(text: widget.doctor.biography);
  late final languages = TextEditingController(
    text: widget.doctor.languages.join(', '),
  );
  final form = GlobalKey<FormState>();
  bool busy = false, failed = false;
  String? message;
  @override
  void dispose() {
    biography.dispose();
    languages.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final doctor = await ref
          .read(doctorRepositoryProvider)
          .saveProfile(
            biography.text,
            languages.text
                .split(',')
                .map((v) => v.trim())
                .where((v) => v.isNotEmpty)
                .toList(),
          );
      if (!mounted) return;
      biography.text = doctor.biography;
      languages.text = doctor.languages.join(', ');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
      ref.invalidate(profileProvider);
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

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: FormPage(
      children: [
        Text(
          widget.doctor.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text('${widget.doctor.qualification} · ${widget.doctor.specialty}'),
        const Notice(
          'Credentials and verification are managed by Pocket Doctor. Contact the platform team for corrections.',
        ),
        TextFormField(
          controller: biography,
          enabled: !busy,
          minLines: 3,
          maxLines: 8,
          maxLength: 2000,
          decoration: const InputDecoration(
            labelText: 'Professional introduction',
          ),
          validator: (value) => value!.trim().isEmpty
              ? 'Enter your professional introduction.'
              : null,
        ),
        TextFormField(
          controller: languages,
          enabled: !busy,
          decoration: const InputDecoration(
            labelText: 'Languages',
            helperText: 'Separate languages with commas',
          ),
          validator: (value) {
            final items = value!
                .split(',')
                .map((v) => v.trim())
                .where((v) => v.isNotEmpty)
                .toList();
            return items.isEmpty ||
                    items.length > 10 ||
                    items.any((v) => v.length < 2 || v.length > 40)
                ? 'Enter 1–10 languages, each 2–40 characters.'
                : null;
          },
        ),
        if (message != null) Notice(message!, error: failed),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(busy ? 'Saving…' : 'Save profile'),
        ),
        OutlinedButton(
          onPressed: busy
              ? null
              : () => ref.read(authProvider.notifier).logout(),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
}
