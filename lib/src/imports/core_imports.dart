// Flutter SDK
export 'package:flutter/material.dart';
export 'package:flutter/cupertino.dart' hide RefreshCallback;
export 'package:flutter/foundation.dart';
export 'package:flutter/services.dart';
export 'package:flutter_native_splash/flutter_native_splash.dart';

export 'package:easy_localization/easy_localization.dart' hide TextDirection, MapExtension;

// Project Core — everything exported through shared.dart (theme, extensions,
// utils, widgets, enums) plus routing and services.
export '../config/app_config.dart';
export '../routing/app_router.dart';
export '../routing/app_routes.dart';
export '../routing/global_navigator.dart';
export '../services/services.dart';
export '../shared/shared.dart';

export '../features/auth/presentation/screens/login_screen.dart';
export '../features/auth/presentation/screens/signup_screen.dart';
export '../features/auth/presentation/screens/forgot_password_screen.dart';
export '../features/home/presentation/screens/home_page.dart';
export '../features/onboarding/presentation/screens/onboarding_page.dart';
export '../features/wallet/presentation/screens/wallet_home.dart';
export '../features/wallet/presentation/widgets/wallet_widgets.dart';
export '../features/transactions/presentation/screens/transactions_list_screen.dart';
export '../features/transactions/presentation/screens/transaction_detail_screen.dart';
export '../features/transactions/presentation/widgets/transactions_widgets.dart';
export '../features/send_receive/presentation/screens/send_money_screen.dart';
export '../features/send_receive/presentation/screens/receive_money_screen.dart';
export '../features/send_receive/presentation/widgets/send_receive_widgets.dart';
