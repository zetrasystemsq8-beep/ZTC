import 'package:ztc_bank/src/imports/imports.dart';
import 'package:ztc_bank/src/features/auth/domain/entities/user.dart';
import 'package:ztc_bank/src/features/auth/domain/repositories/auth_repository.dart';

import 'package:ztc_bank/src/features/auth/data/repositories/auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return SessionNotifier(repository: repo);
});

enum SessionStatus { unknown, unauthenticated, awaitingOtp, authenticated }

class SessionState {
  final SessionStatus status;
  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;

  const SessionState({
    this.status = SessionStatus.unknown,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  SessionState copyWith({
    SessionStatus? status,
    AppUser? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SessionState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final AuthRepository _repository;

  SessionNotifier({required AuthRepository repository})
      : _repository = repository,
        super(const SessionState()) {
    _init();
  }

  Future<void> _init() async {
    final result = await _repository.checkAuthState();
    result.fold(
      (_) => state = const SessionState(status: SessionStatus.unauthenticated),
      (checkResult) {
        switch (checkResult.status) {
          case AuthCheckStatus.authenticated:
            state = SessionState(status: SessionStatus.authenticated, user: checkResult.user);
            break;
          case AuthCheckStatus.awaitingOtp:
            state = const SessionState(status: SessionStatus.awaitingOtp);
            break;
          case AuthCheckStatus.none:
            state = const SessionState(status: SessionStatus.unauthenticated);
            break;
        }
      },
    );
  }

  /// Step 1: ZetraMail + password.
  Future<void> login({required String zetramail, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.login(zetramail: zetramail, password: password);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (_) => state = SessionState(status: SessionStatus.awaitingOtp, isLoading: false),
    );
  }

  Future<void> resendOtp() async {
    final result = await _repository.resendOtp();
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (_) => null,
    );
  }

  /// Step 2: the code from ZetraMail.
  Future<void> verifyOtp(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.verifyOtp(code: code);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (user) => state = SessionState(status: SessionStatus.authenticated, user: user, isLoading: false),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const SessionState(status: SessionStatus.unauthenticated);
  }
}
