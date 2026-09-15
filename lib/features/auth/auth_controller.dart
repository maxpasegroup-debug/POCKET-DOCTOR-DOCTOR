import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/api_failure.dart';
import '../../core/networking/api_client.dart';
import '../../core/storage/session_store.dart';
import 'auth_repository.dart';

final apiProvider = Provider<ApiClient>(
  (ref) => throw StateError('Provide configured API client.'),
);
final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SecureSessionStore(),
);
final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(apiProvider)),
);
final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthState {
  const AuthState({
    this.loading = false,
    this.session,
    this.message,
    this.generation = 0,
  });
  final bool loading;
  final DoctorSession? session;
  final String? message;
  final int generation;
}

class AuthController extends Notifier<AuthState> {
  int _epoch = 0;
  Future<void> _storageWork = Future.value();
  Future<void> _store(Future<void> Function() task) {
    // Serialize writes/deletes so logout cannot race a pending token write.
    final operation = _storageWork.then((_) => task());
    _storageWork = operation.catchError((Object _) {});
    return operation;
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  SessionStore get _storage => ref.read(sessionStoreProvider);
  @override
  AuthState build() {
    final api = ref.read(apiProvider);
    api.onExpired = () {
      unawaited(clear('Your session has ended. Please sign in again.'));
    };
    return const AuthState(loading: true);
  }

  Future<void> clear([String? message]) async {
    final ticket = ++_epoch;
    ref.read(apiProvider).setToken(null);
    state = AuthState(message: message, generation: ticket);
    try {
      await _store(_storage.clear);
    } catch (_) {
      if (ticket == _epoch) {
        state = AuthState(
          message:
              'Local session storage could not be cleared. Please retry logout.',
          generation: ticket,
        );
      }
    }
  }

  Future<void> restore() async {
    final ticket = ++_epoch;
    state = AuthState(loading: true, generation: ticket);
    try {
      final token = await _storage.read();
      if (ticket != _epoch) return;
      if (token == null) {
        state = AuthState(generation: ticket);
        return;
      }
      ref.read(apiProvider).setToken(token);
      await _resolve(ticket);
    } catch (_) {
      if (ticket == _epoch && state.loading) {
        state = AuthState(
          message: 'Could not restore your session. Retry or sign in again.',
          generation: ticket,
        );
      }
    }
  }

  Future<void> _resolve(int ticket, {int? sessionGeneration}) async {
    try {
      final session = await _repository.session();
      if (ticket == _epoch) {
        state = AuthState(
          session: session,
          generation: sessionGeneration ?? ticket,
        );
      }
    } on ApiFailure catch (error) {
      if (ticket != _epoch) return;
      if (error.status == 401 || error.status == 403) {
        await logout();
        state = AuthState(message: error.message, generation: _epoch);
        rethrow;
      }
      state = AuthState(message: error.message, generation: ticket);
      rethrow;
    }
  }

  Future<void> verify(
    String challenge,
    String code, {
    bool registration = false,
  }) async {
    final ticket = ++_epoch;
    final token = await _repository.verifyOtp(
      challenge,
      code,
      registration: registration,
    );
    if (ticket != _epoch) return;
    ref.read(apiProvider).setToken(token);
    try {
      final session = await _repository.session();
      if (ticket != _epoch) return;
      await _store(() => _storage.write(token));
      if (ticket == _epoch) {
        state = AuthState(session: session, generation: ticket);
      }
    } catch (error) {
      if (ticket == _epoch) {
        await logout();
        state = AuthState(
          message: error is ApiFailure
              ? error.message
              : 'Could not securely restore your account. Please try again.',
          generation: _epoch,
        );
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    final sessionGeneration = state.generation;
    final ticket = ++_epoch;
    // Retain the mounted screen under SessionGate's blocking privacy cover
    // until the server accepts the session or the existing failure path clears it.
    state = AuthState(
      loading: true,
      session: state.session,
      generation: sessionGeneration,
    );
    try {
      await _resolve(ticket, sessionGeneration: sessionGeneration);
    } catch (_) {
      if (ticket == _epoch && state.loading) {
        state = AuthState(
          message: 'Could not verify your account. Retry session restoration.',
          generation: ticket,
        );
      }
    }
  }

  Future<void> logout() async {
    final ticket = ++_epoch;
    state = AuthState(loading: true, generation: ticket);
    String? message;
    try {
      await _repository.logout();
    } catch (_) {
      message =
          'Signed out on this device. Server sign-out could not be confirmed; the session will expire automatically.';
    }
    await clear(message);
  }
}
