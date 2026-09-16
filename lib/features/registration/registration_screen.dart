import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import '../../shared/widgets/workspace_widgets.dart';
import '../auth/auth_controller.dart';
import 'registration_repository.dart';
import 'credential_image_preview.dart';

class RegistrationScreen extends ConsumerWidget {
  const RegistrationScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Doctor registration')),
    body: SafeArea(
      child: ref
          .watch(registrationProvider)
          .when(
            loading: () => const LoadingShimmer(label: 'Loading registration'),
            error: (_, _) => FormPage(
              children: [
                const Notice(
                  'Could not load your application. Your saved information remains on the server.',
                  error: true,
                ),
                FilledButton(
                  onPressed: () => ref.invalidate(registrationProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
            data: (app) => RegistrationForm(
              key: ValueKey('${app.id}-${app.status}'),
              application: app,
            ),
          ),
    ),
  );
}

class RegistrationForm extends ConsumerStatefulWidget {
  const RegistrationForm({super.key, required this.application});
  final RegistrationApplication application;
  @override
  ConsumerState<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends ConsumerState<RegistrationForm> {
  final fields = <String, TextEditingController>{};
  final form = GlobalKey<FormState>();
  int step = 0;
  String? localError;
  @override
  void initState() {
    super.initState();
    final p = widget.application.profile.toJson();
    for (final entry in p.entries) {
      fields[entry.key] = TextEditingController(
        text: entry.value is List
            ? (entry.value as List).join(', ')
            : entry.value?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  RegistrationProfile profile() => RegistrationProfile.fromJson({
    ...{for (final e in fields.entries) e.key: e.value.text.trim()},
    'experienceYears': int.tryParse(fields['experienceYears']!.text),
    'feePaise': int.tryParse(fields['feePaise']!.text) ?? -1,
    'languages': fields['languages']!.text
        .split(',')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList(),
  });
  Future<bool> save() async {
    if (!form.currentState!.validate()) return false;
    return ref
        .read(registrationControllerProvider.notifier)
        .run((repo) => repo.save(profile()));
  }

  Future<void> upload(String kind, {String? replaceDocumentId}) async {
    setState(() => localError = null);
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'Credentials',
            extensions: kind == 'PROFILE_PHOTO'
                ? ['jpg', 'jpeg', 'png']
                : ['pdf', 'jpg', 'jpeg', 'png'],
            mimeTypes: kind == 'PROFILE_PHOTO'
                ? ['image/jpeg', 'image/png']
                : ['application/pdf', 'image/jpeg', 'image/png'],
            uniformTypeIdentifiers: kind == 'PROFILE_PHOTO'
                ? ['public.jpeg', 'public.png']
                : ['com.adobe.pdf', 'public.jpeg', 'public.png'],
          ),
        ],
      );
      if (file == null || !mounted) return;
      if (await file.length() > 5 * 1024 * 1024) {
        throw StateError('File too large');
      }
      final ext = file.name.split('.').last.toLowerCase();
      final type = switch (ext) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        _ => throw StateError('Unsupported file'),
      };
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      await ref
          .read(registrationControllerProvider.notifier)
          .run(
            (repo) => repo.upload(
              kind,
              file.name,
              type,
              bytes,
              replaceDocumentId: replaceDocumentId,
            ),
            credentialKind: kind,
          );
    } catch (_) {
      if (mounted) {
        setState(
          () => localError =
              'Choose a PDF, JPEG or PNG up to 5 MB. If upload failed, retry when connected.',
        );
      }
    }
  }

  Widget labelledField(String label, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
      const SizedBox(height: 8),
      Semantics(label: label, child: child),
    ],
  );

  Widget field(
    String key,
    String label, {
    int max = 200,
    bool number = false,
    int lines = 1,
  }) => labelledField(
    label,
    TextFormField(
      controller: fields[key],
      enabled: !ref.watch(registrationControllerProvider).busy,
      maxLength: max,
      maxLines: lines,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: switch (key) {
          'name' => 'Enter your full name',
          'registrationEmail' => 'Enter your email address',
          'specialty' => 'Enter your medical specialization',
          'qualification' => 'Enter your qualification',
          'registrationNumber' => 'Enter your medical registration number',
          'registrationAuthority' => 'Enter your registration council',
          'experienceYears' => 'Enter years of experience',
          'languages' => 'For example: English, Hindi',
          'feePaise' => 'For example: 50000 for INR 500',
          'biography' => 'Write a brief professional introduction',
          _ => 'Enter $label',
        },
      ),
      validator: (v) {
        if (number && v!.isNotEmpty && int.tryParse(v) == null) {
          return 'Enter a whole number.';
        }
        if (key == 'registrationEmail' &&
            v!.isNotEmpty &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
          return 'Enter a valid email.';
        }
        return null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    final operation = ref.watch(registrationControllerProvider);
    final pending = ['SUBMITTED', 'UNDER_REVIEW'].contains(app.status);
    final blocked = ['SUSPENDED', 'INACTIVE'].contains(app.status);
    return Form(
      key: form,
      child: FormPage(
        children: [
          if (operation.busy)
            const LinearProgressIndicator(semanticsLabel: 'Saving securely'),
          if (operation.error != null) Notice(operation.error!, error: true),
          if (localError != null) Notice(localError!, error: true),
          if (blocked) ...[
            const Text('Doctor access is blocked'),
            Notice(app.status),
            const Text('Contact the platform team about your account.'),
          ] else if (pending) ...[
            Text(
              'Application under review',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text(
              'Your professional registration has been submitted. Our verification team is reviewing your information.',
            ),
            Notice('Pending verification · ${app.status.replaceAll('_', ' ')}'),
            if (app.submittedAt != null) Text('Submitted: ${app.submittedAt}'),
            ...review(app),
          ] else if (!app.editable) ...[
            Notice(app.status),
            const Text(
              'Your application is locked. Check status to continue to your authorized workspace.',
            ),
          ] else ...[
            if (app.status == 'REJECTED') ...[
              Text(
                'Application needs correction',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Notice(
                app.reason ?? 'Please review your application.',
                error: true,
              ),
            ],
            Text(
              'Step ${step + 1} of 4 · ${['Basic information', 'Professional information', 'Documents', 'Review application'][step]}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Your mobile number has been verified. Operational access requires platform approval.',
            ),
            if (step == 0) ...[
              Text('Verified mobile: ${app.phone}'),
              field('name', 'Full name', max: 100),
              field('registrationEmail', 'Email', max: 254),
              labelledField(
                'Date of birth (optional)',
                TextFormField(
                  controller: fields['registrationDateOfBirth'],
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Select your date of birth',
                  ),
                  onTap: operation.busy
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            initialDate:
                                DateTime.tryParse(
                                  fields['registrationDateOfBirth']!.text,
                                ) ??
                                DateTime(1990),
                          );
                          if (date != null && mounted) {
                            setState(
                              () => fields['registrationDateOfBirth']!.text =
                                  date.toIso8601String().substring(0, 10),
                            );
                          }
                        },
                ),
              ),
              labelledField(
                'Gender (optional)',
                DropdownButtonFormField<String>(
                  initialValue: fields['registrationGender']!.text,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Not provided')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                    DropdownMenuItem(value: 'MALE', child: Text('Male')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                    DropdownMenuItem(
                      value: 'PREFER_NOT_TO_SAY',
                      child: Text('Prefer not to say'),
                    ),
                  ],
                  onChanged: operation.busy
                      ? null
                      : (v) => fields['registrationGender']!.text = v ?? '',
                ),
              ),
              const Text(
                'Profile photo can be added in the Documents step through private storage.',
              ),
            ],
            if (step == 1) ...[
              field('specialty', 'Medical specialization', max: 100),
              field('qualification', 'Qualification'),
              field('registrationNumber', 'Medical registration number'),
              field('registrationAuthority', 'Registration council'),
              field(
                'experienceYears',
                'Years of experience',
                max: 2,
                number: true,
              ),
              field('languages', 'Languages, separated by commas', max: 400),
              field(
                'feePaise',
                'Consultation fee in paise (100 = INR 1)',
                max: 7,
                number: true,
              ),
              field(
                'biography',
                'Professional introduction',
                max: 2000,
                lines: 4,
              ),
              const Notice(
                'Current consultation type: reservation. Live video, audio and chat are not enabled.',
              ),
            ],
            if (step == 2) ...[
              if (!app.storageAvailable)
                const Notice(
                  'Secure document upload is not available yet. Your draft is saved. Please check again later.',
                  error: true,
                ),
              if (!app.policyConfigured)
                const Notice(
                  'The platform document review policy is not configured. Submission remains unavailable.',
                  error: true,
                ),
              const Text(
                'PDF, JPEG or PNG · up to 5 MB each. Credentials remain private to you and authorized reviewers.',
              ),
              for (final kind in {
                ...app.requiredKinds,
                'QUALIFICATION',
                'REGISTRATION',
                'IDENTITY',
                'PROFILE_PHOTO',
                'ADDITIONAL',
                ...app.documents.map((document) => document.kind),
              })
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(switch (kind) {
                      'QUALIFICATION' => 'Qualification certificate',
                      'REGISTRATION' => 'Medical registration certificate',
                      'IDENTITY' => 'Identity document',
                      'PROFILE_PHOTO' => 'Profile photo',
                      'ADDITIONAL' => 'Additional documents',
                      _ => kind.replaceAll('_', ' '),
                    }, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(switch (kind) {
                      'QUALIFICATION' => 'Your medical degree certificate.',
                      'REGISTRATION' =>
                        'The certificate issued by your medical registration council.',
                      'IDENTITY' =>
                        'An identity document, if requested by the platform.',
                      'PROFILE_PHOTO' =>
                        'Your photograph in JPEG or PNG format.',
                      'ADDITIONAL' =>
                        'Supporting professional credentials, if requested.',
                      _ => 'A document requested by the platform.',
                    }),
                    const SizedBox(height: 8),
                    Text(
                      operation.credentialKind == kind &&
                              operation.uploadPhase != null
                          ? operation.uploadPhase!.name.toUpperCase()
                          : app.documents.any((d) => d.kind == kind)
                          ? 'UPLOADED'
                          : 'NOT UPLOADED',
                    ),
                    OutlinedButton(
                      onPressed: operation.busy || !app.storageAvailable
                          ? null
                          : () => upload(kind),
                      child: Text(
                        'Upload ${kind.toLowerCase().replaceAll('_', ' ')}',
                      ),
                    ),
                    for (final document in app.documents.where(
                      (d) => d.kind == kind,
                    ))
                      CredentialImagePreview(
                        key: ValueKey(document.id),
                        document: document,
                      ),
                    ...documents(app, editable: true, kind: kind),
                  ],
                ),
            ],
            if (step == 3) ...[
              if (app.documentsDeferred)
                const Notice(
                  'Development testing: documents are deferred. Admin approval is still required before Doctor Home access.',
                ),
              ...review(app),
              if (!app.canSubmit)
                const Notice(
                  'Submission needs all required documents and configured secure storage. Save your draft and check again later.',
                  error: true,
                ),
              FilledButton(
                onPressed: operation.busy || !app.canSubmit
                    ? null
                    : () async {
                        if (!await save() || !context.mounted) return;
                        final accepted = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Submit for verification?'),
                            content: const Text(
                              'Your application will be locked during review. Submission does not grant Doctor Home access.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Keep editing'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Submit'),
                              ),
                            ],
                          ),
                        );
                        if (accepted == true && mounted) {
                          await ref
                              .read(registrationControllerProvider.notifier)
                              .run((repo) => repo.submit());
                        }
                      },
                child: Text(
                  app.status == 'REJECTED'
                      ? 'Resubmit application'
                      : 'Submit application',
                ),
              ),
            ],
            Row(
              children: [
                if (step > 0)
                  TextButton(
                    onPressed: operation.busy
                        ? null
                        : () => setState(() => step -= 1),
                    child: const Text('Back'),
                  ),
                const Spacer(),
                if (step < 3)
                  FilledButton(
                    onPressed: operation.busy
                        ? null
                        : () async {
                            if (await save() && mounted) {
                              setState(() => step += 1);
                            }
                          },
                    child: const Text('Save and continue'),
                  ),
              ],
            ),
            OutlinedButton(
              onPressed: operation.busy ? null : save,
              child: const Text('Save draft'),
            ),
          ],
          OutlinedButton(
            onPressed: operation.busy
                ? null
                : () {
                    ref.invalidate(registrationProvider);
                    ref.read(authProvider.notifier).refresh();
                  },
            child: const Text('Check status'),
          ),
        ],
      ),
    );
  }

  List<Widget> documents(
    RegistrationApplication app, {
    bool editable = false,
    String? kind,
  }) => [
    if (kind == null && app.documents.isEmpty)
      const Text('No documents submitted.'),
    for (final d in app.documents.where((d) => kind == null || d.kind == kind))
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(d.kind.toLowerCase().replaceAll('_', ' ')),
        subtitle: Text('${d.name} · ${d.size} bytes'),
        trailing: editable
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Replace document',
                    onPressed:
                        ref.watch(registrationControllerProvider).busy ||
                            !app.storageAvailable
                        ? null
                        : () => upload(d.kind, replaceDocumentId: d.id),
                    icon: const Icon(Icons.upload_file),
                  ),
                  IconButton(
                    tooltip: 'Remove document',
                    onPressed: ref.watch(registrationControllerProvider).busy
                        ? null
                        : () => ref
                              .read(registrationControllerProvider.notifier)
                              .run((repo) => repo.remove(d.id)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              )
            : null,
      ),
  ];
  List<Widget> review(RegistrationApplication app) {
    final p = app.editable ? profile() : app.profile;
    return [
      Text('Name: ${p.name}'),
      Text('Mobile: ${app.phone}'),
      Text('Email: ${p.email}'),
      Text('Date of birth: ${p.dateOfBirth}'),
      Text('Gender: ${p.gender}'),
      Text('Specialization: ${p.specialty}'),
      Text('Qualification: ${p.qualification}'),
      Text('Registration: ${p.number} · ${p.council}'),
      Text('Experience: ${p.experience ?? "Not provided"} years'),
      Text('Languages: ${p.languages.join(', ')}'),
      Text('Consultation fee: ${p.feePaise} paise'),
      Text(p.biography),
      ...documents(app),
    ];
  }
}
