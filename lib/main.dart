import 'src/imports/core_imports.dart';
import 'src/imports/packages_imports.dart';
import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(
    widgetsBinding: WidgetsBinding.instance,
  );

  try {
    await EasyLocalization.ensureInitialized();
    await dotenv.load(fileName: '.env');
    await AppConfig.init();
    await HiveService.instance.init();

    runApp(
      const LocalizationWrapper(
        child: StateWrapper(
          child: App(),
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('APP STARTUP ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Startup Error:\n$e'),
          ),
        ),
      ),
    );
  } finally {
    FlutterNativeSplash.remove();
  }
}
