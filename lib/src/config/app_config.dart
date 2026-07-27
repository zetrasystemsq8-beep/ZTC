import '../imports/core_imports.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class AppConfig {
  AppConfig._();

  static late final Dio dio;
  static late final http.Client httpClient;

  static Future<void> init() async {
    final supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://ssmwuihkafrulmvtiuam.supabase.co');
    final supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzbXd1aWhrYWZydWxtdnRpdWFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4Mjk2NjAsImV4cCI6MjA5NjQwNTY2MH0.e1PxmDW77ZhbonS-Z96SWA_sPyVGedzpZNZbJQz7pQo');

    dio = Dio(
      BaseOptions(
        baseUrl: '$supabaseUrl/rest/v1',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
          'apikey': supabaseAnonKey,
          'Prefer': 'return=representation',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.info('🌐 [DIO] REQUEST[${options.method}] => PATH: ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.info('✅ [DIO] RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: (e, handler) {
          AppLogger.error('❌ [DIO] ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
          handler.next(e);
        },
      ),
    );

    httpClient = http.Client();
  }
}
