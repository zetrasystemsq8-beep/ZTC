// lib/src/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_routes.dart';
import '../features/auth/presentation/providers/session_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/verify_otp_screen.dart';
import '../features/home/presentation/screens/home_page.dart';
import '../features/wallet/presentation/screens/wallet_home.dart';
import '../features/transactions/presentation/screens/transactions_list_screen.dart';
import '../features/transactions/presentation/screens/transaction_detail_screen.dart';
import '../features/send_receive/presentation/screens/send_money_screen.dart';
import '../features/send_receive/presentation/screens/receive_money_screen.dart';
import '../features/linked_apps/linked_apps.dart';

class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen<SessionState>(sessionProvider, (_, __) => notifyListeners());
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final loc = state.matchedLocation;

      switch (session.status) {
        case SessionStatus.unknown:
          return loc == AppRoutes.splash ? null : AppRoutes.splash;
        case SessionStatus.unauthenticated:
          return loc == AppRoutes.login ? null : AppRoutes.login;
        case SessionStatus.awaitingOtp:
          return loc == '/verify-otp' ? null : '/verify-otp';
        case SessionStatus.authenticated:
          if (loc == AppRoutes.login ||
              loc == '/verify-otp' ||
              loc == AppRoutes.splash) {
            return AppRoutes.home;
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) => const VerifyOtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (context, state) => const WalletHome(),
      ),
      GoRoute(
        path: AppRoutes.transactions,
        builder: (context, state) => const TransactionsListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => TransactionDetailScreen(
              transactionId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.sendMoney,
        builder: (context, state) => const SendMoneyScreen(),
      ),
      GoRoute(
        path: AppRoutes.receiveMoney,
        builder: (context, state) => const ReceiveMoneyScreen(),
      ),
      GoRoute(
        path: AppRoutes.linkedApps,
        builder: (context, state) => const LinkedAppsScreen(),
      ),
      GoRoute(
        // FIXED: was '/app-send/:appId' (old path, no longer used by
        // linked_apps.dart), now matches the renamed top-up flow that
        // LinkedAppsScreen actually navigates to.
        path: AppRoutes.appTopUp,
        builder: (context, state) {
          final appId = state.pathParameters['appId']!;
          return AppSendMoneyScreen(appId: appId);
        },
      ),
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
