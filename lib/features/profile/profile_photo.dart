import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../core/errors/api_failure.dart';
import '../auth/auth_controller.dart';
import '../registration/credential_image_preview.dart';
import '../registration/registration_repository.dart';

final profilePhotoProvider = FutureProvider.autoDispose<RegistrationDocument?>((
  ref,
) async {
  ref.watch(authProvider.select((s) => s.generation));
  try {
    final application = await ref.watch(registrationRepositoryProvider).load();
    final photos = application.documents.where(
      (document) => document.kind == 'PROFILE_PHOTO',
    );
    return photos.isEmpty ? null : photos.last;
  } on ApiFailure catch (error) {
    // Doctors provisioned before registration may not have an application.
    if (error.status == 404) return null;
    rethrow;
  }
}, retry: (_, _) => null);

class ProfilePhoto extends ConsumerWidget {
  const ProfilePhoto({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(profilePhotoProvider)
      .when(
        loading: () =>
            const LoadingShimmer(height: 120, label: 'Loading profile photo'),
        error: (_, _) => Column(
          children: [
            const Text('Could not load your profile photo.'),
            TextButton(
              onPressed: () => ref.invalidate(profilePhotoProvider),
              child: const Text('Retry profile photo'),
            ),
          ],
        ),
        data: (photo) => photo == null
            ? const Column(
                children: [
                  Icon(Icons.account_circle_outlined, size: 72),
                  Text('No profile photo uploaded.'),
                ],
              )
            : CredentialImagePreview(key: ValueKey(photo.id), document: photo),
      );
}
