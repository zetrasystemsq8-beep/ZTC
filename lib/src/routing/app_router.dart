import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/session_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/verify_otp_screen.dart';
import '../features/home/presentation/screens/home_page.dart';

class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen<SessionState>(sessionProvider, (_, __) => notifyListeners());
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final loc = state.matchedLocation;

      switch (session.status) {
        case SessionStatus.unknown:
          return loc == '/splash' ? null : '/splash';
        case SessionStatus.unauthenticated:
          return loc == '/login' ? null : '/login';
        case SessionStatus.awaitingOtp:
          return loc == '/verify-otp' ? null : '/verify-otp';
        case SessionStatus.authenticated:
          if (loc == '/login' || loc == '/verify-otp' || loc == '/splash') return '/home';
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/verify-otp', builder: (context, state) => const VerifyOtpScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      // No '/signup' or '/forgot-password' — Zetra-login-only client.
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
