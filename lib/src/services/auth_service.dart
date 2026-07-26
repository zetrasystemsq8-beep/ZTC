import '../utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Zetra-only auth over Supabase: this app never creates accounts — it
/// authenticates existing Zetra users via ZetraMail + password, followed
/// by a mandatory OTP step, exactly like NaijaLearn/NAI/ZetraMail.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  static const String _otpVerifiedMetaKey = 'ztc_otp_verified';

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  bool get isOtpVerifiedForCurrentSession =>
      currentUser?.userMetadata?[_otpVerifiedMetaKey] == true;

  Future<String?> _resolveLoginEmail(String identifier) async {
    final result = await _client.rpc(
      'resolve_login_email',
      params: {'p_identifier': identifier},
    );
    return result is String ? result : null;
  }

  /// Step 1: ZetraMail + password. Resolves the internal auth_email, signs
  /// in, clears any stale otp-verified flag, then requests a fresh code.
  /// Does NOT authenticate the app yet — verifyOtp() does.
  FutureEither<void> zetraLogin({
    required String zetramail,
    required String password,
  }) async {
    return runTask(() async {
      final normalized = zetramail.trim().toLowerCase();
      if (normalized.isEmpty) {
        throw const ServerFailure('Invalid ZetraMail or password.');
      }

      final resolvedEmail = await _resolveLoginEmail(normalized);
      if (resolvedEmail == null || resolvedEmail.isEmpty) {
        throw const ServerFailure('Invalid ZetraMail or password.');
      }

      final response = await _client.auth.signInWithPassword(
        email: resolvedEmail,
        password: password,
      );
      if (response.user == null) {
        throw const ServerFailure('Invalid ZetraMail or password.');
      }

      await _client.auth.updateUser(UserAttributes(data: {_otpVerifiedMetaKey: false}));
      await _client.rpc('request_otp');
    }, requiresNetwork: true);
  }

  FutureEither<void> resendOtp() async {
    return runTask(() async {
      if (currentSession == null) {
        throw const ServerFailure("You're not signed in. Please log in again.");
      }
      await _client.rpc('request_otp');
    }, requiresNetwork: true);
  }

  /// Step 2: verifies the code via the backend's own verify_otp RPC (not
  /// Supabase's built-in verifyOTP, which rejects the internal auth email
  /// format). On success, marks the session verified, ensures a wallet
  /// exists, and returns the user's profile row.
  FutureEither<Map<String, dynamic>?> verifyOtp(String code) async {
    return runTask(() async {
      if (currentSession == null) {
        throw const ServerFailure("You're not signed in. Please log in again.");
      }

      final result = await _client.rpc('verify_otp', params: {'p_code': code.trim()});
      if (result != true) {
        throw const ServerFailure('Invalid or expired code. Please try again.');
      }

      await _client.auth.updateUser(UserAttributes(data: {_otpVerifiedMetaKey: true}));

      final userId = currentUser!.id;
      await _ensureWalletExists(userId);

      return _client.from('profiles').select().eq('id', userId).maybeSingle();
    }, requiresNetwork: true);
  }

  FutureEither<void> logout() async {
    return runTask(() async {
      try {
        await _client.auth.updateUser(UserAttributes(data: {_otpVerifiedMetaKey: false}));
      } catch (_) {
        // non-fatal
      }
      await _client.auth.signOut();
    }, requiresNetwork: true);
  }

  /// Used on app start to resolve the correct session state. Returns:
  /// - null if there's no session at all (unauthenticated)
  /// - a profile map if there IS a session AND OTP was already verified
  /// - throws a sentinel Failure with message 'awaiting_otp' if a session
  ///   exists but OTP verification never completed (app was killed
  ///   mid-flow) — the repository maps this to the awaitingOtp status.
  FutureEither<Map<String, dynamic>?> getCurrentUser() async {
    return runTask(() async {
      final session = currentSession;
      if (session == null) return null;

      if (!isOtpVerifiedForCurrentSession) {
        throw const ServerFailure('awaiting_otp');
      }

      return _client.from('profiles').select().eq('id', currentUser!.id).maybeSingle();
    });
  }

  Future<void> _ensureWalletExists(String userId) async {
    final existing = await _client.from('wallets').select().eq('user_id', userId).maybeSingle();
    if (existing == null) {
      await _client.from('wallets').insert({'user_id': userId, 'balance': 0});
    }
  }
}
