import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'src/imports/packages_imports.dart';
import 'src/imports/core_imports.dart';
import 'src/app.dart';
import 'src/config/app_config.dart';
import 'src/routing/app_router.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    final supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    final supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    await EasyLocalization.ensureInitialized();
    await AppConfig.init();

  } catch (e, s) {
    debugPrint('❌ Startup Error: $e');
    debugPrintStack(stackTrace: s);
    FlutterNativeSplash.remove();
    runApp(ErrorApp(error: e.toString()));
    return;
  }

  FlutterNativeSplash.remove();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = buildRouter(ref);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, child) {
        return MaterialApp.router(
          title: 'ztc_bank',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true),
          darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
          themeMode: ThemeMode.system,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          routerConfig: appRouter,
        );
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
