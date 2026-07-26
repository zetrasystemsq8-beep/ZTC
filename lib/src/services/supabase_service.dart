import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase access point. Auth here is Zetra-only: this app
/// never creates accounts — it authenticates existing Zetra users via
/// ZetraMail + password, followed by a mandatory OTP step, exactly like
/// NaijaLearn. No sign-up, no forgot-password flow.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static Session? get currentSession => _client.auth.currentSession;

  static const String _otpVerifiedMetaKey = 'ztc_otp_verified';

  static const String invalidCredentialsMessage = 'Invalid ZetraMail or password.';
  static const String invalidOtpMessage = 'Invalid or expired code. Please try again.';
  static const String profileLoadErrorMessage = 'Could not load your profile. Please try again.';

  /// True only once the CURRENT session has completed the mandatory OTP
  /// step. Backed by Supabase Auth user metadata so an app restart
  /// mid-verification doesn't skip straight to Home.
  static bool get isOtpVerifiedForCurrentSession =>
      currentUser?.userMetadata?[_otpVerifiedMetaKey] == true;

  static Future<String?> _resolveLoginEmail(String identifier) async {
    final result = await _client.rpc(
      'resolve_login_email',
      params: {'p_identifier': identifier},
    );
    return result is String ? result : null;
  }

  /// Step 1: ZetraMail + password. Resolves the typed ZetraMail to the
  /// internal auth_email, signs in, clears any stale otp-verified flag
  /// from a previous session, then requests a fresh code.
  static Future<void> zetraLogin({
    required String zetramail,
    required String password,
  }) async {
    final normalized = zetramail.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw Exception(invalidCredentialsMessage);
    }

    String? resolvedEmail;
    try {
      resolvedEmail = await _resolveLoginEmail(normalized);
    } on PostgrestException {
      throw Exception(invalidCredentialsMessage);
    }

    if (resolvedEmail == null || resolvedEmail.isEmpty) {
      throw Exception(invalidCredentialsMessage);
    }

    AuthResponse response;
    try {
      response = await _client.auth.signInWithPassword(
        email: resolvedEmail,
        password: password,
      );
    } on AuthException {
      throw Exception(invalidCredentialsMessage);
    }

    if (response.user == null) {
      throw Exception(invalidCredentialsMessage);
    }

    try {
      await _client.auth.updateUser(UserAttributes(data: {_otpVerifiedMetaKey: false}));
    } catch (_) {
      // non-fatal
    }

    try {
      await _client.rpc('request_otp');
    } on PostgrestException {
      throw Exception('Could not send your verification code. Please try again.');
    }
  }

  static Future<void> resendOtp() async {
    if (currentSession == null) {
      throw Exception("You're not signed in. Please log in again.");
    }
    try {
      await _client.rpc('request_otp');
    } on PostgrestException {
      throw Exception('Could not resend code. Please try again.');
    }
  }

  /// Step 2: verifies the code against the backend's own verify_otp RPC
  /// (not Supabase's built-in verifyOTP — that rejects the internal auth
  /// email format used by the Zetra ecosystem). On success, marks this
  /// session verified and ensures a wallet exists for first-time users
  /// of this app.
  static Future<void> verifyOtp(String code) async {
    if (currentSession == null) {
      throw Exception("You're not signed in. Please log in again.");
    }

    dynamic result;
    try {
      result = await _client.rpc('verify_otp', params: {'p_code': code.trim()});
    } on PostgrestException {
      throw Exception(invalidOtpMessage);
    }

    if (result != true) {
      throw Exception(invalidOtpMessage);
    }

    try {
      await _client.auth.updateUser(UserAttributes(data: {_otpVerifiedMetaKey: true}));
    } catch (_) {
      // non-fatal
    }

    final userId = currentUser?.id;
    if (userId != null) {
      await ensureWalletExists(userId);
    }
  }

  static Future<void> signOut() async {
    try {
      await _client.auth.updateUser(UserAttributes(data: {_otpVerifiedMetaKey: false}));
    } catch (_) {
      // non-fatal
    }
    await _client.auth.signOut();
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    } on PostgrestException {
      throw Exception(profileLoadErrorMessage);
    }
  }

  /// Creates a wallet only if this Zetra user doesn't already have one in
  /// this app — safe to call on every login, not just the first.
  static Future<void> ensureWalletExists(String userId) async {
    final existing = await _client.from('wallets').select().eq('user_id', userId).maybeSingle();
    if (existing == null) {
      await createWallet(userId);
    }
  }

  static Future<void> createWallet(String userId) async {
    await _client.from('wallets').insert({'user_id': userId, 'balance': 0});
  }

  static Future<Map<String, dynamic>?> getWallet(String userId) async {
    return await _client.from('wallets').select().eq('user_id', userId).maybeSingle();
  }

  // Keep any existing transaction/transfer methods here unchanged —
  // this file only replaces the sign-up/sign-in surface.
}
