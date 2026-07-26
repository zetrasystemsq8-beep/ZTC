// lib/src/features/auth/presentation/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';

/// Three-stage auth flow, matching NaijaLearn: password alone never
/// authenticates. A session only counts as "authenticated" once the
/// mandatory OTP step has also completed.
enum AuthStage { unauthenticated, awaitingOtp, authenticated }

class AuthState {
  final AuthStage stage;
  final User? user;
  const AuthState({required this.stage, this.user});
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _loadInitialState();
  }

  /// Resolves the correct starting stage on app launch. This matters
  /// because Supabase creates a valid session the instant the password
  /// check succeeds — BEFORE OTP verification runs. So a bare "is there a
  /// session?" check isn't enough: if the app was killed while the user
  /// was copying their code from ZetraMail, this correctly sends them back
  /// to the OTP screen instead of skipping straight to authenticated.
  void _loadInitialState() {
    final session = SupabaseService.currentSession;
    if (session == null) {
      state = const AsyncValue.data(AuthState(stage: AuthStage.unauthenticated));
    } else if (SupabaseService.isOtpVerifiedForCurrentSession) {
      state = AsyncValue.data(AuthState(stage: AuthStage.authenticated, user: SupabaseService.currentUser));
    } else {
      state = AsyncValue.data(AuthState(stage: AuthStage.awaitingOtp, user: SupabaseService.currentUser));
    }
  }

  /// Step 1: ZetraMail + password. This app never creates accounts — only
  /// existing Zetra users can sign in. Always lands on awaitingOtp on
  /// success; never goes straight to authenticated.
  Future<void> login({required String zetramail, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.zetraLogin(zetramail: zetramail, password: password);
      state = AsyncValue.data(AuthState(stage: AuthStage.awaitingOtp, user: SupabaseService.currentUser));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resendOtp() async {
    try {
      await SupabaseService.resendOtp();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Step 2: the code from ZetraMail. On success, ensures a wallet exists
  /// for first-time users of this app (handled inside
  /// SupabaseService.verifyOtp) and moves to authenticated.
  Future<void> verifyOtp(String code) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.verifyOtp(code);
      state = AsyncValue.data(AuthState(stage: AuthStage.authenticated, user: SupabaseService.currentUser));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    state = const AsyncValue.data(AuthState(stage: AuthStage.unauthenticated));
  }
}
