// dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // kIsWeb, defaultTargetPlatform, TargetPlatform
import 'auth_service.dart';

String _apiBaseUrl() {
  if (kIsWeb) {
    // Esempio: stai aprendo il front-end da http://192.168.1.23:8080
    final uri = Uri.base; // schema/host/port del frontend
    return Uri(
      scheme: uri.scheme, // http
      host: uri.host, // 192.168.1.23
      port: 8000, // <-- metti la porta del tuo backend
      path: '/api/v1/',
    ).toString();
  }

  // Non-web (build mobile/desktop). Evito dart:io per compatibilità web.
  if (defaultTargetPlatform == TargetPlatform.android) {
    // Alias host per l'emulatore Android -> macchina host
    return 'http://10.0.2.2:8000/api/v1/';
  }

  // iOS device/desktop durante lo sviluppo: di solito backend locale
  return 'http://localhost:8000/api/v1/';
}

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  final Dio dio;

  DioClient._internal()
      : dio = Dio(
          BaseOptions(
            baseUrl: _apiBaseUrl(),
            // Su Web i timeout contano meno (dipende dal browser), ma li aumento comunque
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthService.instance.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await AuthService.instance.refreshToken();
            if (refreshed) {
              final newToken = await AuthService.instance.getAccessToken();
              if (newToken != null) {
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newToken';
                final opts = Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                );
                try {
                  final response = await dio.request(
                    error.requestOptions.path,
                    options: opts,
                    data: error.requestOptions.data,
                    queryParameters: error.requestOptions.queryParameters,
                  );
                  return handler.resolve(response);
                } catch (_) {}
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(String path, {dynamic data, Options? options}) {
    return dio.post<T>(path, data: data, options: options);
  }

  Future<Response<T>> put<T>(String path, {dynamic data, Options? options}) {
    return dio.put<T>(path, data: data, options: options);
  }

  Future<Response<T>> delete<T>(String path, {Options? options}) {
    return dio.delete<T>(path, options: options);
  }
}
