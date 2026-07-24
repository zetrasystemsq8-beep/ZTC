// lib/src/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';
import 'package:ztc_bank/src/routing/app_router.dart';
import 'package:ztc_bank/src/theme/app_theme.dart';
import 'package:ztc_bank/src/widgets/skeleton_wrapper.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = buildRouter(ref);
    
    final current = _buildMaterialApp(context, appRouter);
    return ScreenUtilWrapper(child: current);
  }

  Widget _buildMaterialApp(BuildContext context, GoRouter router) {
    return MaterialApp.router(
      title: 'ztc_bank',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(primaryColorHex: '#6750A4'),
      darkTheme: buildDarkTheme(primaryColorHex: '#6750A4'),
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        Widget current = child!;
        current = SkeletonWrapper(child: current);
        return current;
      },
    );
  }
}
