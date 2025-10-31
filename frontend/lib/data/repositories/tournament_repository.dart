import 'package:dio/dio.dart';
import 'package:tickup/data/models/tournament.dart';

class TournamentRepository {
  final Dio _dio;

  TournamentRepository({Dio? dio}) : _dio = dio ?? _createDefaultDio();

  static Dio _createDefaultDio() {
    final dio = Dio();
    dio.options.baseUrl = 'https://your-api-base-url.com/api/v1'; // TODO: Replace with actual base URL
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Add interceptors for auth, logging, etc.
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // TODO: Add authentication token
        // options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) {
        // TODO: Add error logging
        print('Tournament API Error: ${error.message}');
        handler.next(error);
      },
    ));
    
    return dio;
  }

  /// Get all active tournaments
  Future<List<Tournament>> getActiveTournaments() async {
    try {
      final response = await _dio.get('/tournaments/active');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => Tournament.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all tournaments (including completed)
  Future<List<Tournament>> getAllTournaments() async {
    try {
      final response = await _dio.get('/tournaments');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => Tournament.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get tournament by ID with full details
  Future<Tournament> getTournament(String tournamentId) async {
    try {
      final response = await _dio.get('/tournaments/$tournamentId');
      return Tournament.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get tournaments where current user is participating
  Future<List<Tournament>> getMyTournaments() async {
    try {
      final response = await _dio.get('/tournaments/my');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => Tournament.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Convert a pool to tournament
  Future<Tournament> convertPoolToTournament(
    String poolId,
    TournamentCreateRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/pools/$poolId/convert-to-tournament',
        data: request.toJson(),
      );
      return Tournament.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Start tournament manually (override schedule)
  Future<Tournament> startTournament(String tournamentId) async {
    try {
      final response = await _dio.post('/tournaments/$tournamentId/start');
      return Tournament.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get leaderboard for tournament or specific phase
  Future<TournamentLeaderboard> getLeaderboard(
    String tournamentId, {
    String? phaseId,
  }) async {
    try {
      String endpoint = '/tournaments/$tournamentId/leaderboard';
      if (phaseId != null) {
        endpoint = '/tournaments/$tournamentId/phases/$phaseId/leaderboard';
      }

      final response = await _dio.get(endpoint);
      return TournamentLeaderboard.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Join current active phase (if qualified)
  Future<void> joinCurrentPhase(String tournamentId) async {
    try {
      // Get current phase first
      final tournament = await getTournament(tournamentId);
      if (tournament.currentPhaseInfo == null) {
        throw Exception('No active phase to join');
      }

      await _dio.post(
        '/tournaments/$tournamentId/phases/${tournament.currentPhaseInfo!.id}/join',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Start a game session in tournament context
  Future<String> startTournamentSession(
    String tournamentId,
    String phaseId,
  ) async {
    try {
      final response = await _dio.post(
        '/tournaments/$tournamentId/phases/$phaseId/sessions/start',
      );
      return response.data['game_session_id'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get tournament history/completed tournaments
  Future<List<Tournament>> getTournamentHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get('/tournaments/history', queryParameters: {
        'page': page,
        'limit': limit,
      });
      final List<dynamic> data = response.data['tournaments'] as List<dynamic>;
      return data
          .map((json) => Tournament.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get tournament phases details
  Future<List<TournamentPhase>> getTournamentPhases(String tournamentId) async {
    try {
      final response = await _dio.get('/tournaments/$tournamentId/phases');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => TournamentPhase.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Cancel tournament (admin only)
  Future<void> cancelTournament(String tournamentId, String reason) async {
    try {
      await _dio.post('/tournaments/$tournamentId/cancel', data: {
        'reason': reason,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get my participation status in tournament
  Future<TournamentParticipant?> getMyParticipation(String tournamentId) async {
    try {
      final response = await _dio.get('/tournaments/$tournamentId/my-participation');
      if (response.data == null) return null;
      return TournamentParticipant.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleError(e);
    }
  }

  /// Private error handling
  Exception _handleError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return Exception(
          e.response?.data['detail'] ?? 'Richiesta non valida',
        );
      case 401:
        return Exception('Accesso non autorizzato');
      case 403:
        return Exception('Accesso negato');
      case 404:
        return Exception('Torneo non trovato');
      case 409:
        return Exception(
          e.response?.data['detail'] ?? 'Conflitto nella richiesta',
        );
      case 500:
        return Exception('Errore del server');
      default:
        return Exception(
          e.response?.data['detail'] ?? 
          'Errore di rete: ${e.message}',
        );
    }
  }
}

// Repository provider (singleton)
class TournamentRepositoryProvider {
  static TournamentRepository? _instance;
  
  static TournamentRepository get instance {
    _instance ??= TournamentRepository();
    return _instance!;
  }

  static void setInstance(TournamentRepository repository) {
    _instance = repository;
  }
}