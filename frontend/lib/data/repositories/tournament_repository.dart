import 'package:tickup/data/models/tournament.dart';
import 'package:tickup/data/remote/tournament_remote_datasource.dart';

class TournamentRepository {
  final TournamentRemoteDataSource _remote = TournamentRemoteDataSource();

  // Tournament operations
  Future<List<Tournament>> fetchActiveTournaments() => _remote.getActiveTournaments();
  Future<List<Tournament>> fetchAllTournaments() => _remote.getAllTournaments();
  Future<Tournament> fetchTournament(String tournamentId) => _remote.getTournament(tournamentId);
  Future<List<Tournament>> fetchMyTournaments() => _remote.getMyTournaments();
  
  // Tournament management
  Future<Tournament> convertPoolToTournament(
    String poolId,
    TournamentCreateRequest request,
  ) => _remote.convertPoolToTournament(poolId, request);
  
  Future<Tournament> startTournament(String tournamentId) => _remote.startTournament(tournamentId);
  Future<void> cancelTournament(String tournamentId, String reason) => 
      _remote.cancelTournament(tournamentId, reason);
  
  // Leaderboards and participation
  Future<TournamentLeaderboard> fetchLeaderboard(
    String tournamentId, {
    String? phaseId,
  }) => _remote.getLeaderboard(tournamentId, phaseId: phaseId);
  
  Future<TournamentParticipant?> fetchMyParticipation(String tournamentId) => 
      _remote.getMyParticipation(tournamentId);
  
  // Tournament phases
  Future<List<TournamentPhase>> fetchTournamentPhases(String tournamentId) => 
      _remote.getTournamentPhases(tournamentId);
  
  // Game sessions
  Future<void> joinCurrentPhase(String tournamentId) async {
    // Get current phase first
    final tournament = await fetchTournament(tournamentId);
    if (tournament.currentPhaseInfo == null) {
      throw Exception('No active phase to join');
    }
    
    return _remote.joinCurrentPhase(tournamentId, tournament.currentPhaseInfo!.id);
  }
  
  Future<String> startTournamentSession(
    String tournamentId,
    String phaseId,
  ) => _remote.startTournamentSession(tournamentId, phaseId);
  
  // History
  Future<List<Tournament>> fetchTournamentHistory({
    int page = 1,
    int limit = 20,
  }) => _remote.getTournamentHistory(page: page, limit: limit);
}