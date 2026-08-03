/// Centralized route path constants for GoRouter.
///
/// Use these variables instead of raw strings throughout the app.
/// Example:
/// context.go(AppRoutes.onboarding);

abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';

  static const String home = '/';

  static const String onboarding = '/onboarding';

  static const String login = '/login';

  static const String signup = '/signup';

  static const String forgotPassword = '/forgot-password';

  static const String wallet = '/wallet';

  static const String transactions = '/transactions';

  static const String sendMoney = '/send';

  static const String receiveMoney = '/receive';

  // Grouped feature hubs

  static const String payments = '/payments';

  static const String cards = '/cards';

  static const String account = '/account';

  // Linked apps (Send to Apps / Fund App Balance)

  static const String linkedApps = '/apps';

  /// Route PATTERN — used only when registering the GoRoute itself.
  static const String appTopUp = '/app-topup/:appId';

  /// Route BUILDER — used when navigating, e.g.
  /// context.push(AppRoutes.appTopUpPath('naijalearn'))
  static String appTopUpPath(String appId) => '/app-topup/$appId';
}
