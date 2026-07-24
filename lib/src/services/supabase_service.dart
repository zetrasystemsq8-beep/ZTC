import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static final client = Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static User? get currentUser => auth.currentUser;

  static Session? get currentSession => auth.currentSession;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return auth.signUp(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() {
    return auth.signOut();
  }

  static Future<void> resetPassword(String email) {
    return auth.resetPasswordForEmail(email);
  }
}
