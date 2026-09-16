import '../../core/errors/api_failure.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/networking/api_client.dart';
import '../auth/auth_controller.dart';

typedef RegistrationJson = Map<String, dynamic>;

class RegistrationProfile {
  RegistrationProfile.fromJson(RegistrationJson j)
    : name = j['name'] as String,
      email = j['registrationEmail'] as String,
      dateOfBirth = j['registrationDateOfBirth'] as String,
      gender = j['registrationGender'] as String,
      qualification = j['qualification'] as String,
      specialty = j['specialty'] as String,
      biography = j['biography'] as String,
      council = j['registrationAuthority'] as String,
      number = j['registrationNumber'] as String,
      experience = j['experienceYears'] as int?,
      languages = List<String>.from(j['languages'] as List),
      feePaise = j['feePaise'] as int;
  final String name,
      email,
      dateOfBirth,
      gender,
      qualification,
      specialty,
      biography,
      council,
      number;
  final int? experience;
  final List<String> languages;
  final int feePaise;
  RegistrationJson toJson() => {
    'name': name,
    'registrationEmail': email,
    'registrationDateOfBirth': dateOfBirth,
    'registrationGender': gender,
    'qualification': qualification,
    'specialty': specialty,
    'biography': biography,
    'registrationAuthority': council,
    'registrationNumber': number,
    'experienceYears': experience,
    'languages': languages,
    'feePaise': feePaise,
  };
}

class RegistrationDocument {
  RegistrationDocument.fromJson(RegistrationJson j)
    : id = j['id'] as String,
      kind = j['kind'] as String,
      name = j['fileName'] as String,
      size = j['size'] as int;
  final String id, kind, name;
  final int size;
}

class RegistrationApplication {
  RegistrationApplication.fromJson(RegistrationJson j)
    : id = j['id'] as String,
      status = j['status'] as String,
      phone = j['phone'] as String? ?? '',
      reason = j['rejectionReason'] as String?,
      submittedAt = j['submittedAt'] as String?,
      editable = j['editable'] as bool,
      profile = RegistrationProfile.fromJson(j['profile'] as RegistrationJson),
      documents = (j['documents'] as List)
          .map((d) => RegistrationDocument.fromJson(d as RegistrationJson))
          .toList(),
      documentsDeferred =
          (j['documentPolicy'] as RegistrationJson)['deferred'] == true,
      storageAvailable =
          (j['documentPolicy'] as RegistrationJson)['storageAvailable'] as bool,
      policyConfigured =
          (j['documentPolicy'] as RegistrationJson)['configured'] as bool,
      requiredKinds = List<String>.from(
        (j['documentPolicy'] as RegistrationJson)['requiredKinds'] as List,
      );
  final String id, status, phone;
  final String? reason, submittedAt;
  final bool editable, storageAvailable, policyConfigured, documentsDeferred;
  final List<String> requiredKinds;
  final List<RegistrationDocument> documents;
  final RegistrationProfile profile;
  bool get canSubmit =>
      editable &&
      (documentsDeferred ||
          (storageAvailable &&
              policyConfigured &&
              requiredKinds.every(
                (kind) => documents.any((d) => d.kind == kind),
              )));
}

class RegistrationRepository {
  RegistrationRepository(this.api);
  final ApiClient api;
  static const path = '/doctor/registration';
  Future<RegistrationApplication> load() async =>
      RegistrationApplication.fromJson(await api.request(path));
  Future<RegistrationApplication> save(RegistrationProfile profile) async =>
      RegistrationApplication.fromJson(
        await api.request(path, method: 'PATCH', body: profile.toJson()),
      );
  Future<RegistrationApplication> submit() async =>
      RegistrationApplication.fromJson(
        await api.request('$path/submit', method: 'POST', body: {}),
      );
  Future<Uint8List> image(String documentId) async {
    final json = await api.request(
      '$path/documents/${Uri.encodeComponent(documentId)}',
    );
    if (!['image/jpeg', 'image/png'].contains(json['contentType'])) {
      throw const ApiFailure('This document is not a supported image.');
    }
    return base64Decode(json['contentBase64'] as String);
  }

  Future<RegistrationApplication> upload(
    String kind,
    String name,
    String type,
    Uint8List bytes, {
    String? replaceDocumentId,
  }) async => RegistrationApplication.fromJson(
    await api.request(
      '$path/documents',
      method: 'POST',
      requestTimeout: const Duration(seconds: 90),
      body: {
        'replaceDocumentId': ?replaceDocumentId,
        'kind': kind,
        'fileName': name,
        'contentType': type,
        'contentBase64': base64Encode(bytes),
      },
    ),
  );
  Future<RegistrationApplication> remove(String id) async =>
      RegistrationApplication.fromJson(
        await api.request('$path/documents/$id', method: 'DELETE'),
      );
}

final registrationRepositoryProvider = Provider(
  (ref) => RegistrationRepository(ref.watch(apiProvider)),
);
final registrationProvider = FutureProvider.autoDispose((ref) {
  ref.watch(authProvider.select((s) => s.generation));
  return ref.watch(registrationRepositoryProvider).load();
});

enum CredentialUploadPhase { uploading, uploaded, failed }

class RegistrationOperation {
  const RegistrationOperation({
    this.busy = false,
    this.error,
    this.credentialKind,
    this.uploadPhase,
  });
  final String? credentialKind;
  final CredentialUploadPhase? uploadPhase;
  final bool busy;
  final String? error;
}

final registrationControllerProvider =
    NotifierProvider.autoDispose<RegistrationController, RegistrationOperation>(
      RegistrationController.new,
    );

class RegistrationController extends Notifier<RegistrationOperation> {
  @override
  RegistrationOperation build() => const RegistrationOperation();
  Future<bool> run(
    Future<RegistrationApplication> Function(RegistrationRepository) action, {
    String? credentialKind,
  }) async {
    if (state.busy) return false;
    state = RegistrationOperation(
      busy: true,
      credentialKind: credentialKind,
      uploadPhase: credentialKind == null
          ? null
          : CredentialUploadPhase.uploading,
    );
    try {
      await action(ref.read(registrationRepositoryProvider));
      if (!ref.mounted) return false;
      state = RegistrationOperation(
        credentialKind: credentialKind,
        uploadPhase: credentialKind == null
            ? null
            : CredentialUploadPhase.uploaded,
      );
      ref.invalidate(registrationProvider);
      return true;
    } catch (error) {
      if (ref.mounted) {
        state = RegistrationOperation(
          credentialKind: credentialKind,
          uploadPhase: credentialKind == null
              ? null
              : CredentialUploadPhase.failed,
          error: error is ApiFailure
              ? error.message
              : 'The request could not be completed. Your saved draft is safe. Check your connection and retry.',
        );
      }
      return false;
    }
  }
}
