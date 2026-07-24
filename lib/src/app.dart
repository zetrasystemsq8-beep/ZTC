// lib/src/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'src/imports/core_imports.dart';
import 'src/routing/app_router.dart';

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
        current = SessionListenerWrapper(child: current);
        return current;
      },
    );
  }
}
