import 'dart:io'; // <-- added for exit()
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart'; // <-- added
import 'src/imports/packages_imports.dart';
import 'src/imports/core_imports.dart';
import 'src/app.dart';
import 'src/config/app_config.dart';
import 'src/routing/app_router.dart';
import 'src/theme/theme.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    debugPrint('======================================');
    debugPrint('SUPABASE_URL: $supabaseUrl');
    debugPrint('SUPABASE_ANON_KEY EMPTY: ${supabaseAnonKey.isEmpty}');
    debugPrint('======================================');

    if (supabaseUrl.isEmpty) {
      throw Exception(
        'SUPABASE_URL is empty. Check your GitHub Actions --dart-define.',
      );
    }

    if (supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY is empty. Check your GitHub Actions --dart-define.',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    await EasyLocalization.ensureInitialized();
    await AppConfig.init();

    FlutterNativeSplash.remove();

    // ----- VERSION CHECK (inserted before runApp) -----
    await _checkAppVersion();
    // ------------------------------------------------

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
  } catch (e, s) {
    debugPrint('❌ Startup Error: $e');
    debugPrintStack(stackTrace: s);

    FlutterNativeSplash.remove();

    runApp(
      ErrorApp(error: e.toString()),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(goRouterProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, child) {
        return MaterialApp.router(
          title: 'ztc_bank',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(primaryColorHex: '#6750A4'),
          darkTheme: buildDarkTheme(primaryColorHex: '#6750A4'),
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

  const ErrorApp({
    super.key,
    required this.error,
  });

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
                const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Initialization Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SelectableText(
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

// ----- VERSION CHECK FUNCTION (added at bottom) -----
Future<void> _checkAppVersion() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final response = await Supabase.instance.client
        .from('app_versions')
        .select()
        .eq('app_name', 'ztc_bank')
        .maybeSingle();

    if (response != null) {
      final minVersion = response['min_version'] as String;
      final forceUpdate = response['force_update'] as bool;

      if (forceUpdate && currentVersion != minVersion) {
        exit(0); // Block app
      }
    }
  } catch (e) {
    print('Version check: $e');
  }
}
// ----------------------------------------------------
