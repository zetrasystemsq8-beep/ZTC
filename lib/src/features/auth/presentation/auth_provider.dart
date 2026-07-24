import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _loadUser();
  }

  void _loadUser() {
    state = AsyncValue.data(SupabaseService.currentUser);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      await SupabaseService.signIn(
        email: email,
        password: password,
      );

      state = AsyncValue.data(
        SupabaseService.currentUser,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
      );

      // Create wallet for new user
      final userId = response.user?.id;
      if (userId != null) {
        await SupabaseService.createWallet(userId);
      }

      state = AsyncValue.data(
        SupabaseService.currentUser,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();

    state = const AsyncValue.data(null);
  }
}
