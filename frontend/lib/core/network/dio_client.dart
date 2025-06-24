import 'package:dio/dio.dart';
import 'auth_service.dart';

/// Classe singleton per gestire tutte le richieste HTTP con Dio.
/// Aggiunge automaticamente il token Bearer (se presente)
/// e gestisce il refresh in caso di errore 401.
class DioClient {
  // Singleton: creo una sola istanza e la riuso in tutta l'app
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  // Istanza interna di Dio
  final Dio dio;

  // Costruttore privato
  DioClient._internal()
      : dio = Dio(BaseOptions(
          baseUrl: 'http://10.0.2.2:8000/api/v1/',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        )) {
    // Aggiungo gli interceptors al client Dio
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        // Prima di ogni richiesta: aggiunge il token se presente
        onRequest: (options, handler) async {
          final token = await AuthService.instance.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options); // prosegue la richiesta
        },

        // In caso di errore: gestisce il token scaduto
        onError: (error, handler) async {
          // Se ricevo 401, provo una volta a fare il refresh del token
          if (error.response?.statusCode == 401) {
            final refreshed = await AuthService.instance.refreshToken();
            if (refreshed) {
              final newToken = await AuthService.instance.getAccessToken();
              if (newToken != null) {
                // Aggiorno l’header e ripeto la richiesta
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
                  return handler.resolve(response); // risposta sostitutiva
                } catch (e) {
                  return handler.next(error); // fallisce comunque
                }
              }
            }
          }

          // Se non era 401 o refresh fallito → prosegue con l'errore
          handler.next(error);
        },
      ),
    );
  }

  // Metodo GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // Metodo POST
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return dio.post<T>(
      path,
      data: data,
      options: options,
    );
  }

  // Metodo PUT
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return dio.put<T>(
      path,
      data: data,
      options: options,
    );
  }

  // Metodo DELETE
  Future<Response<T>> delete<T>(
    String path, {
    Options? options,
  }) {
    return dio.delete<T>(
      path,
      options: options,
    );
  }
}
