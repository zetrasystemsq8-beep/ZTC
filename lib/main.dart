import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/imports/packages_imports.dart';
import 'src/imports/core_imports.dart';
import 'src/app.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // 1. Load .env FIRST
    await dotenv.load(fileName: '.env');

    // 2. Initialize Supabase
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env');
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

    // 3. Initialize other stuff
    await EasyLocalization.ensureInitialized();
    await AppConfig.init();
  } catch (e, s) {
    debugPrint('❌ Startup Error: $e');
    debugPrintStack(stackTrace: s);
  }

  FlutterNativeSplash.remove();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const StateWrapper(child: App()),
    ),
  );
}
