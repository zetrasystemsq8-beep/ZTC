import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/verify_otp_screen.dart';

// TODO: point this at your real home screen
import '../features/home/presentation/screens/home_screen.dart';

/// Bridges Riverpod's authProvider changes into something GoRouter's
/// `refreshListenable` understands, so route redirects re-evaluate the
/// instant auth stage changes (login → awaitingOtp → authenticated).
class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<AuthState>>(authProvider, (_, __) => notifyListeners());
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final loc = state.matchedLocation;

      // Auth state hasn't resolved yet — hold on the splash route.
      if (authState.isLoading) {
        return loc == '/splash' ? null : '/splash';
      }

      final stage = authState.valueOrNull?.stage ?? AuthStage.unauthenticated;

      switch (stage) {
        case AuthStage.authenticated:
          if (loc == '/login' || loc == '/verify-otp' || loc == '/splash') {
            return '/home';
          }
          return null;
        case AuthStage.awaitingOtp:
          if (loc != '/verify-otp') return '/verify-otp';
          return null;
        case AuthStage.unauthenticated:
          if (loc != '/login') return '/login';
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) => const VerifyOtpScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      // Deliberately no '/signup' or '/forgot-password' routes — this app
      // is a pure Zetra-login client, same as NaijaLearn.
    ],
  );
});

/// Minimal splash shown only for the brief window while authProvider
/// resolves its initial state (session check). The redirect above moves
/// past this automatically once that resolves.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
