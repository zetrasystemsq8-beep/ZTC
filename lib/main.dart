import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'src/imports/core_imports.dart';
import 'src/imports/packages_imports.dart';
import 'src/app.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await EasyLocalization.ensureInitialized();
    await dotenv.load(fileName: '.env');
    await AppConfig.init();
    await HiveService.instance.init();
  } catch (e, s) {
    debugPrint('Startup Error: $e');
    debugPrintStack(stackTrace: s);
  }

  FlutterNativeSplash.remove();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const StateWrapper(
        child: App(),
      ),
    ),
  );
}
