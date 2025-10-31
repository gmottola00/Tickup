import 'package:dio/dio.dart';
import 'package:tickup/data/models/tournament.dart';
import 'package:tickup/core/network/dio_client.dart';
import 'package:tickup/core/config/env_config.dart';

class TournamentRemoteDataSource {
  final Dio dio = DioClient().dio;

  /// Get all active tournaments
  Future<List<Tournament>> getActiveTournaments() async {
    if (EnvConfig.isDevelopment) {
      return _mockActiveTournaments();
    }
    
    // Backend route: GET /api/v1/tournaments/active
    final res = await dio.get('tournaments/active');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic> ? (raw['data'] as List?) : null) ??
            <dynamic>[];
    return list
        .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get all tournaments (including completed)
  Future<List<Tournament>> getAllTournaments() async {
    if (EnvConfig.isDevelopment) {
      return _mockAllTournaments();
    }
    
    // Backend route: GET /api/v1/tournaments
    final res = await dio.get('tournaments');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic> ? (raw['data'] as List?) : null) ??
            <dynamic>[];
    return list
        .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get tournament by ID with full details
  Future<Tournament> getTournament(String tournamentId) async {
    if (EnvConfig.isDevelopment) {
      return _mockTournamentDetails(tournamentId);
    }
    
    // Backend route: GET /api/v1/tournaments/{id}
    final res = await dio.get('tournaments/$tournamentId');
    return Tournament.fromJson(res.data as Map<String, dynamic>);
  }

  /// Get tournaments where current user is participating
  Future<List<Tournament>> getMyTournaments() async {
    if (EnvConfig.isDevelopment) {
      return _mockMyTournaments();
    }
    
    // Backend route: GET /api/v1/tournaments/my
    final res = await dio.get('tournaments/my');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic> ? (raw['data'] as List?) : null) ??
            <dynamic>[];
    return list
        .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Convert a pool to tournament
  Future<Tournament> convertPoolToTournament(
    String poolId,
    TournamentCreateRequest request,
  ) async {
    // Backend route: POST /api/v1/pools/{id}/convert-to-tournament
    final res = await dio.post(
      'pools/$poolId/convert-to-tournament',
      data: request.toJson(),
    );
    return Tournament.fromJson(res.data as Map<String, dynamic>);
  }

  /// Start tournament manually (override schedule)
  Future<Tournament> startTournament(String tournamentId) async {
    // Backend route: POST /api/v1/tournaments/{id}/start
    final res = await dio.post('tournaments/$tournamentId/start');
    return Tournament.fromJson(res.data as Map<String, dynamic>);
  }

  /// Get leaderboard for tournament or specific phase
  Future<TournamentLeaderboard> getLeaderboard(
    String tournamentId, {
    String? phaseId,
  }) async {
    if (EnvConfig.isDevelopment) {
      return _mockLeaderboard(tournamentId, phaseId);
    }
    
    String endpoint = 'tournaments/$tournamentId/leaderboard';
    if (phaseId != null) {
      endpoint = 'tournaments/$tournamentId/phases/$phaseId/leaderboard';
    }

    final res = await dio.get(endpoint);
    return TournamentLeaderboard.fromJson(res.data as Map<String, dynamic>);
  }

  /// Join current active phase (if qualified)
  Future<void> joinCurrentPhase(String tournamentId, String phaseId) async {
    // Backend route: POST /api/v1/tournaments/{id}/phases/{phaseId}/join
    await dio.post('tournaments/$tournamentId/phases/$phaseId/join');
  }

  /// Start a game session in tournament context
  Future<String> startTournamentSession(
    String tournamentId,
    String phaseId,
  ) async {
    // Backend route: POST /api/v1/tournaments/{id}/phases/{phaseId}/sessions/start
    final res = await dio.post(
      'tournaments/$tournamentId/phases/$phaseId/sessions/start',
    );
    return res.data['game_session_id'] as String;
  }

  /// Get tournament history/completed tournaments
  Future<List<Tournament>> getTournamentHistory({
    int page = 1,
    int limit = 20,
  }) async {
    if (EnvConfig.isDevelopment) {
      return _mockTournamentHistory();
    }
    
    // Backend route: GET /api/v1/tournaments/history
    final res = await dio.get('tournaments/history', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final raw = res.data;
    final list = (raw is Map<String, dynamic> ? (raw['tournaments'] as List?) : null) ??
        <dynamic>[];
    return list
        .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get tournament phases details
  Future<List<TournamentPhase>> getTournamentPhases(String tournamentId) async {
    if (EnvConfig.isDevelopment) {
      return _mockTournamentPhases(tournamentId);
    }
    
    // Backend route: GET /api/v1/tournaments/{id}/phases
    final res = await dio.get('tournaments/$tournamentId/phases');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic> ? (raw['data'] as List?) : null) ??
            <dynamic>[];
    return list
        .map((e) => TournamentPhase.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cancel tournament (admin only)
  Future<void> cancelTournament(String tournamentId, String reason) async {
    // Backend route: POST /api/v1/tournaments/{id}/cancel
    await dio.post('tournaments/$tournamentId/cancel', data: {
      'reason': reason,
    });
  }

  /// Get my participation status in tournament
  Future<TournamentParticipant?> getMyParticipation(String tournamentId) async {
    if (EnvConfig.isDevelopment) {
      return _mockMyParticipation(tournamentId);
    }
    
    try {
      // Backend route: GET /api/v1/tournaments/{id}/my-participation
      final res = await dio.get('tournaments/$tournamentId/my-participation');
      if (res.data == null) return null;
      return TournamentParticipant.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  // Mock data for development
  Future<List<Tournament>> _mockActiveTournaments() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();
    return [
      Tournament(
        id: 'tournament-1',
        poolId: 'pool-1',
        title: 'Pixel Adventure Championship',
        description: 'Compete through multiple levels to win the Nintendo Switch!',
        status: 'active',
        totalPhases: 3,
        currentPhase: 1,
        scheduledStartAt: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(days: 1)),
        participantsCount: 32,
        currentPhaseDeadline: now.add(const Duration(days: 2)),
        myStatus: 'qualified',
        currentPhaseInfo: TournamentPhase(
          id: 'phase-1-1',
          tournamentId: 'tournament-1',
          phaseNumber: 1,
          gameId: 'pixel-adventure',
          levelId: 'Level-01',
          title: 'Qualification Round',
          description: 'Complete Level-01 to advance',
          durationHours: 72,
          eliminationRule: {'type': 'top_percentage', 'value': 50},
          status: 'active',
          startedAt: now.subtract(const Duration(hours: 2)),
          deadlineAt: now.add(const Duration(days: 2)),
          participantsCount: 32,
          qualifiedCount: 0,
        ),
      ),
      Tournament(
        id: 'tournament-2',
        poolId: 'pool-2',
        title: 'Speed Run Challenge',
        description: 'Fast-paced tournament for experienced players',
        status: 'ready',
        totalPhases: 2,
        currentPhase: 0,
        scheduledStartAt: now.add(const Duration(hours: 12)),
        createdAt: now.subtract(const Duration(hours: 6)),
        participantsCount: 16,
        myStatus: 'active',
      ),
    ];
  }

  Future<List<Tournament>> _mockAllTournaments() async {
    final active = await _mockActiveTournaments();
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    
    final completed = [
      Tournament(
        id: 'tournament-completed-1',
        poolId: 'pool-completed-1',
        title: 'Halloween Special Tournament',
        description: 'Completed tournament with spooky levels',
        status: 'completed',
        totalPhases: 3,
        currentPhase: 3,
        createdAt: now.subtract(const Duration(days: 10)),
        completedAt: now.subtract(const Duration(days: 3)),
        participantsCount: 64,
        myStatus: 'eliminated',
      ),
    ];
    
    return [...active, ...completed];
  }

  Future<List<Tournament>> _mockMyTournaments() async {
    final all = await _mockAllTournaments();
    // Return only tournaments where user is participating
    return all.where((t) => 
      t.myStatus != null && t.myStatus != 'not_participating'
    ).toList();
  }

  Future<Tournament> _mockTournamentDetails(String tournamentId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final tournaments = await _mockActiveTournaments();
    final tournament = tournaments.firstWhere(
      (t) => t.id == tournamentId,
      orElse: () => tournaments.first,
    );

    // Add phases details
    final phases = await _mockTournamentPhases(tournamentId);
    return tournament.copyWith(phases: phases);
  }

  Future<List<TournamentPhase>> _mockTournamentPhases(String tournamentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    
    return [
      TournamentPhase(
        id: 'phase-$tournamentId-1',
        tournamentId: tournamentId,
        phaseNumber: 1,
        gameId: 'pixel-adventure',
        levelId: 'Level-01',
        title: 'Qualification Round',
        description: 'Complete Level-01 with minimum 500 points',
        durationHours: 72,
        eliminationRule: {'type': 'top_percentage', 'value': 50},
        minScore: 500,
        status: 'active',
        startedAt: now.subtract(const Duration(hours: 2)),
        deadlineAt: now.add(const Duration(days: 2)),
        participantsCount: 32,
        qualifiedCount: 0,
      ),
      TournamentPhase(
        id: 'phase-$tournamentId-2',
        tournamentId: tournamentId,
        phaseNumber: 2,
        gameId: 'pixel-adventure',
        levelId: 'Level-02',
        title: 'Semi Finals',
        description: 'Navigate through Level-02 challenges',
        durationHours: 72,
        eliminationRule: {'type': 'top_percentage', 'value': 50},
        minScore: 800,
        status: 'scheduled',
        participantsCount: 0,
        qualifiedCount: 0,
      ),
      TournamentPhase(
        id: 'phase-$tournamentId-3',
        tournamentId: tournamentId,
        phaseNumber: 3,
        gameId: 'pixel-adventure',
        levelId: 'Level-03',
        title: 'Grand Final',
        description: 'The ultimate challenge - winner takes all!',
        durationHours: 96,
        eliminationRule: {'type': 'min_score', 'value': 1200},
        minScore: 1200,
        status: 'scheduled',
        participantsCount: 0,
        qualifiedCount: 0,
      ),
    ];
  }

  Future<TournamentLeaderboard> _mockLeaderboard(String tournamentId, String? phaseId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final participants = [
      TournamentParticipant(
        id: 'participant-1',
        tournamentId: tournamentId,
        phaseId: phaseId ?? 'phase-$tournamentId-1',
        playerId: 'player-1',
        qualified: true,
        bestScore: 1250,
        bestTimeSeconds: 180,
        sessionsCount: 3,
        lastPlayedAt: DateTime.now().subtract(const Duration(hours: 1)),
        qualifiedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      TournamentParticipant(
        id: 'participant-2',
        tournamentId: tournamentId,
        phaseId: phaseId ?? 'phase-$tournamentId-1',
        playerId: 'player-2',
        qualified: true,
        bestScore: 1180,
        bestTimeSeconds: 195,
        sessionsCount: 5,
        lastPlayedAt: DateTime.now().subtract(const Duration(hours: 2)),
        qualifiedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      TournamentParticipant(
        id: 'participant-3',
        tournamentId: tournamentId,
        phaseId: phaseId ?? 'phase-$tournamentId-1',
        playerId: 'current-user',
        qualified: false,
        bestScore: 980,
        bestTimeSeconds: 220,
        sessionsCount: 2,
        lastPlayedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
    ];

    return TournamentLeaderboard(
      tournamentId: tournamentId,
      phaseId: phaseId,
      participants: participants,
    );
  }

  Future<TournamentParticipant?> _mockMyParticipation(String tournamentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return TournamentParticipant(
      id: 'my-participation-$tournamentId',
      tournamentId: tournamentId,
      phaseId: 'phase-$tournamentId-1',
      playerId: 'current-user',
      qualified: false,
      bestScore: 980,
      bestTimeSeconds: 220,
      sessionsCount: 2,
      lastPlayedAt: DateTime.now().subtract(const Duration(minutes: 45)),
    );
  }

  Future<List<Tournament>> _mockTournamentHistory() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    
    return [
      Tournament(
        id: 'tournament-history-1',
        poolId: 'pool-history-1',
        title: 'Summer Championship 2025',
        description: 'Epic summer tournament with beach-themed levels',
        status: 'completed',
        totalPhases: 4,
        currentPhase: 4,
        createdAt: now.subtract(const Duration(days: 45)),
        completedAt: now.subtract(const Duration(days: 30)),
        participantsCount: 128,
        myStatus: 'winner',
      ),
      Tournament(
        id: 'tournament-history-2',
        poolId: 'pool-history-2',
        title: 'Spring Festival Tournament',
        description: 'Colorful spring-themed adventure',
        status: 'completed',
        totalPhases: 3,
        currentPhase: 3,
        createdAt: now.subtract(const Duration(days: 80)),
        completedAt: now.subtract(const Duration(days: 70)),
        participantsCount: 64,
        myStatus: 'eliminated',
      ),
    ];
  }
}