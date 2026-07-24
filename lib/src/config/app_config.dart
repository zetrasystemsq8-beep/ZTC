import '../imports/core_imports.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AppConfig {
  AppConfig._();

  static late final Dio dio;
  static late final http.Client httpClient;

  // Supabase configuration
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  static late final String baseUrl;

  static Future<void> init() async {
    baseUrl = '$supabaseUrl/rest/v1';

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
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
          AppLogger.info(
            '🌐 [DIO] REQUEST[${options.method}] => PATH: ${options.path}',
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.info(
            '✅ [DIO] RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (e, handler) {
          AppLogger.error(
            '❌ [DIO] ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}',
          );
          handler.next(e);
        },
      ),
    );

    httpClient = http.Client();
  }
}
