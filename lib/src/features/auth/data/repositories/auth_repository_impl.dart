import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/auth/domain/entities/user.dart';
import 'package:ztc_bank/src/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService = AuthService.instance;

  AppUser _mapToUser(Map<String, dynamic> data, {String? fallbackEmail}) {
    return AppUser(
      id: (data['id'] ?? _authService.currentUser?.id ?? '').toString(),
      email: data['email'] ?? fallbackEmail ?? _authService.currentUser?.email ?? '',
      name: data['username'] ?? data['name'],
      photoUrl: data['avatar_url'] ?? data['photoUrl'],
    );
  }

  @override
  FutureEither<void> login({
    required String zetramail,
    required String password,
  }) {
    return _authService.zetraLogin(zetramail: zetramail, password: password);
  }

  @override
  FutureEither<void> resendOtp() {
    return _authService.resendOtp();
  }

  @override
  FutureEither<AppUser> verifyOtp({required String code}) async {
    final result = await _authService.verifyOtp(code);

    return result.flatMap((profileData) {
      if (profileData == null) {
        return left(const ServerFailure('Could not load your profile. Please try again.'));
      }
      return right(_mapToUser(profileData));
    });
  }

  @override
  FutureEither<void> logout() {
    return _authService.logout();
  }

  @override
  FutureEither<AuthCheckResult> checkAuthState() async {
    final result = await _authService.getCurrentUser();

    return result.match(
      (failure) {
        if (failure.message == 'awaiting_otp') {
          return right(const AuthCheckResult(status: AuthCheckStatus.awaitingOtp));
        }
        return left(failure);
      },
      (profileData) {
        if (profileData == null) {
          return right(const AuthCheckResult(status: AuthCheckStatus.none));
        }
        return right(AuthCheckResult(
          status: AuthCheckStatus.authenticated,
          user: _mapToUser(profileData),
        ));
      },
    );
  }
}
