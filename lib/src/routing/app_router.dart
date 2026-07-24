import 'package:go_router/go_router.dart';

import 'package:ztc_bank/src/routing/global_navigator.dart';
import 'package:ztc_bank/src/routing/app_routes.dart';

import 'package:ztc_bank/src/features/auth/presentation/screens/login_screen.dart';
import 'package:ztc_bank/src/features/auth/presentation/screens/signup_screen.dart';
import 'package:ztc_bank/src/features/auth/presentation/screens/forgot_password_screen.dart';

import 'package:ztc_bank/src/features/home/presentation/screens/home_page.dart';
import 'package:ztc_bank/src/features/onboarding/presentation/screens/onboarding_page.dart';

import 'package:ztc_bank/src/features/wallet/presentation/screens/wallet_home.dart';

import 'package:ztc_bank/src/features/transactions/presentation/screens/transactions_list_screen.dart';
import 'package:ztc_bank/src/features/transactions/presentation/screens/transaction_detail_screen.dart';

import 'package:ztc_bank/src/features/send_receive/presentation/screens/send_money_screen.dart';
import 'package:ztc_bank/src/features/send_receive/presentation/screens/receive_money_screen.dart';

import 'package:ztc_bank/src/features/payments/presentation/screens/payments_screen.dart';
import 'package:ztc_bank/src/features/cards/presentation/screens/cards_screen.dart';
import 'package:ztc_bank/src/features/account/presentation/screens/account_screen.dart';


final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,

  // Developer mode: skip onboarding/login
  initialLocation: AppRoutes.home,

  routes: <RouteBase>[

    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) =>
          const OnboardingPage(),
    ),

    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) =>
          const LoginScreen(),
    ),

    GoRoute(
      path: AppRoutes.signup,
      name: 'signup',
      builder: (context, state) =>
          const SignupScreen(),
    ),

    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'forgotPassword',
      builder: (context, state) =>
          const ForgotPasswordScreen(),
    ),

    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) =>
          const HomePage(),
    ),

    GoRoute(
      path: AppRoutes.wallet,
      name: 'wallet',
      builder: (context, state) =>
          const WalletHome(),
    ),

    GoRoute(
      path: AppRoutes.transactions,
      name: 'transactions',
      builder: (context, state) =>
          const TransactionsListScreen(),
    ),

    GoRoute(
      path: '${AppRoutes.transactions}/:id',
      name: 'transactionDetail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TransactionDetailScreen(
          transactionId: id,
        );
      },
    ),

    GoRoute(
      path: AppRoutes.sendMoney,
      name: 'sendMoney',
      builder: (context, state) =>
          const SendMoneyScreen(),
    ),

    GoRoute(
      path: AppRoutes.receiveMoney,
      name: 'receiveMoney',
      builder: (context, state) =>
          const ReceiveMoneyScreen(),
    ),


    // New grouped features

    GoRoute(
      path: '/payments',
      name: 'payments',
      builder: (context, state) =>
          const PaymentsScreen(),
    ),

    GoRoute(
      path: '/cards',
      name: 'cards',
      builder: (context, state) =>
          const CardsScreen(),
    ),

    GoRoute(
      path: '/account',
      name: 'account',
      builder: (context, state) =>
          const AccountScreen(),
    ),
  ],
);
