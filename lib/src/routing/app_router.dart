// lib/src/routing/app_router.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ztc_bank/src/routing/global_navigator.dart';
import 'package:ztc_bank/src/routing/app_routes.dart';

// Auth Provider
import 'package:ztc_bank/src/features/auth/presentation/providers/session_provider.dart';

// Auth Screens
import 'package:ztc_bank/src/features/auth/presentation/screens/login_screen.dart';
import 'package:ztc_bank/src/features/auth/presentation/screens/signup_screen.dart';
import 'package:ztc_bank/src/features/auth/presentation/screens/forgot_password_screen.dart';

// Core
import 'package:ztc_bank/src/features/home/presentation/screens/home_page.dart';
import 'package:ztc_bank/src/features/onboarding/presentation/screens/onboarding_page.dart';

// Wallet
import 'package:ztc_bank/src/features/wallet/presentation/screens/wallet_home.dart';

// Transactions
import 'package:ztc_bank/src/features/transactions/presentation/screens/transactions_list_screen.dart';
import 'package:ztc_bank/src/features/transactions/presentation/screens/transaction_detail_screen.dart';

// Send / Receive
import 'package:ztc_bank/src/features/send_receive/presentation/screens/send_money_screen.dart';
import 'package:ztc_bank/src/features/send_receive/presentation/screens/receive_money_screen.dart';

// Payments
import 'package:ztc_bank/src/features/payments/presentation/screens/payments_screen.dart';

// Cards
import 'package:ztc_bank/src/features/cards/presentation/screens/cards_screen.dart';

// Account
import 'package:ztc_bank/src/features/account/presentation/screens/account_screen.dart';

GoRouter buildRouter(WidgetRef ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.login,

    redirect: (context, state) {
      final session = ref.watch(sessionProvider);

      final isAuthenticated =
          session.status == SessionStatus.authenticated;

      final isLoading =
          session.status == SessionStatus.unknown;

      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.forgotPassword;

      // Wait until the auth state has been determined.
      if (isLoading) {
        return null;
      }

      // Not logged in -> Login
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      // Logged in -> Home
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },

    routes: [
      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // Login
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Signup
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Forgot Password
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Home
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // Wallet
      GoRoute(
        path: AppRoutes.wallet,
        name: 'wallet',
        builder: (context, state) => const WalletHome(),
      ),

      // Transactions
      GoRoute(
        path: AppRoutes.transactions,
        name: 'transactions',
        builder: (context, state) => const TransactionsListScreen(),
      ),

      GoRoute(
        path: '${AppRoutes.transactions}/:id',
        name: 'transactionDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TransactionDetailScreen(transactionId: id);
        },
      ),

      // Send Money
      GoRoute(
        path: AppRoutes.sendMoney,
        name: 'sendMoney',
        builder: (context, state) => const SendMoneyScreen(),
      ),

      // Receive Money
      GoRoute(
        path: AppRoutes.receiveMoney,
        name: 'receiveMoney',
        builder: (context, state) => const ReceiveMoneyScreen(),
      ),

      // Payments
      GoRoute(
        path: AppRoutes.payments,
        name: 'payments',
        builder: (context, state) => const PaymentsScreen(),
      ),

      // Cards
      GoRoute(
        path: AppRoutes.cards,
        name: 'cards',
        builder: (context, state) => const CardsScreen(),
      ),

      // Account
      GoRoute(
        path: AppRoutes.account,
        name: 'account',
        builder: (context, state) => const AccountScreen(),
      ),
    ],
  );
}
