import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../auth/auth_controller.dart';
import 'registration_repository.dart';

final credentialImageProvider = FutureProvider.autoDispose
    .family<MemoryImage, String>((ref, id) async {
      ref.watch(authProvider.select((s) => s.generation));
      final bytes = await ref.watch(registrationRepositoryProvider).image(id);
      final image = MemoryImage(bytes);
      if (ref.mounted) ref.onDispose(() => image.evict());
      return image;
    }, retry: (_, _) => null);

class CredentialImagePreview extends ConsumerWidget {
  const CredentialImagePreview({super.key, required this.document});
  final RegistrationDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // PDFs retain their existing document row. The server also validates MIME.
    if (!RegExp(
      r'\.(png|jpe?g)$',
      caseSensitive: false,
    ).hasMatch(document.name)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ref
          .watch(credentialImageProvider(document.id))
          .when(
            loading: () => const LoadingShimmer(
              height: 160,
              label: 'Loading uploaded image',
            ),
            error: (_, _) => Column(
              children: [
                const Text('Could not load the uploaded image.'),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(credentialImageProvider(document.id)),
                  child: const Text('Retry image preview'),
                ),
              ],
            ),
            data: (image) => Image(
              image: image,
              height: 180,
              fit: BoxFit.contain,
              semanticLabel:
                  'Uploaded ${document.kind.toLowerCase().replaceAll('_', ' ')} image',
              errorBuilder: (_, _, _) =>
                  const Text('This image could not be displayed.'),
            ),
          ),
    );
  }
}
