import 'package:ztc_bank/src/utils/utils.dart';
import 'package:ztc_bank/src/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  /// Step 1: ZetraMail + password. Success means an OTP was sent — the
  /// caller must move to the OTP screen next; this does not authenticate.
  FutureEither<void> login({
    required String zetramail,
    required String password,
  });

  FutureEither<void> resendOtp();

  /// Step 2: verifies the code. Only this fully authenticates.
  FutureEither<AppUser> verifyOtp({required String code});

  FutureEither<void> logout();

  /// Resolves current session on app start. Distinguishes "no session"
  /// from "session exists but OTP still pending" via the returned
  /// AuthCheckResult.
  FutureEither<AuthCheckResult> checkAuthState();
}

enum AuthCheckStatus { none, awaitingOtp, authenticated }

class AuthCheckResult {
  final AuthCheckStatus status;
  final AppUser? user;
  const AuthCheckResult({required this.status, this.user});
}
