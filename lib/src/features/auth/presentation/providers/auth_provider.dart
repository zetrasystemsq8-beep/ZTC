import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ztc_bank/src/services/supabase_service.dart';

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
