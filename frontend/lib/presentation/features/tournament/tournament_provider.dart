import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/tournament.dart';
import 'package:tickup/data/repositories/tournament_repository.dart';

// Tournament Repository Provider
final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  return TournamentRepository();
});

// Active Tournaments Provider
final activeTournamentsProvider = FutureProvider<List<Tournament>>((ref) async {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.fetchActiveTournaments();
});

// All Tournaments Provider
final allTournamentsProvider = FutureProvider<List<Tournament>>((ref) async {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.fetchAllTournaments();
});

// My Tournaments Provider
final myTournamentsProvider = FutureProvider<List<Tournament>>((ref) async {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.fetchMyTournaments();
});

// Tournament Details Provider (by ID)
final tournamentProvider = FutureProvider.family<Tournament, String>((ref, tournamentId) async {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.fetchTournament(tournamentId);
});

// Tournament Leaderboard Provider
final tournamentLeaderboardProvider = FutureProvider.family<TournamentLeaderboard, String>((ref, tournamentId) async {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.fetchLeaderboard(tournamentId);
});

// Tournament Phase Leaderboard Provider
final tournamentPhaseLeaderboardProvider = FutureProvider.family<TournamentLeaderboard, TournamentPhaseLeaderboardParams>((ref, params) async {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.fetchLeaderboard(params.tournamentId, phaseId: params.phaseId);
});

// Tournament Phases Provider
final tournamentPhasesProvider = FutureProvider.family<List<TournamentPhase>, String>((ref, tournamentId) async {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.fetchTournamentPhases(tournamentId);
});

// My Tournament Participation Provider
final myTournamentParticipationProvider = FutureProvider.family<TournamentParticipant?, String>((ref, tournamentId) async {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.fetchMyParticipation(tournamentId);
});

// Tournament History Provider
final tournamentHistoryProvider = FutureProvider<List<Tournament>>((ref) async {
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.fetchTournamentHistory();
});

// Tournament Controller for actions
final tournamentControllerProvider = Provider<TournamentController>((ref) {
  return TournamentController(ref.read(tournamentRepositoryProvider));
});

class TournamentController {
  final TournamentRepository _repository;

  TournamentController(this._repository);

  /// Convert pool to tournament
  Future<Tournament> convertPoolToTournament(
    String poolId,
    TournamentCreateRequest request,
  ) async {
    return _repository.convertPoolToTournament(poolId, request);
  }

  /// Start tournament manually
  Future<Tournament> startTournament(String tournamentId) async {
    return _repository.startTournament(tournamentId);
  }

  /// Join current active phase
  Future<void> joinCurrentPhase(String tournamentId) async {
    return _repository.joinCurrentPhase(tournamentId);
  }

  /// Start game session in tournament
  Future<String> startTournamentSession(
    String tournamentId,
    String phaseId,
  ) async {
    return _repository.startTournamentSession(tournamentId, phaseId);
  }

  /// Cancel tournament
  Future<void> cancelTournament(String tournamentId, String reason) async {
    return _repository.cancelTournament(tournamentId, reason);
  }
}

// Notifier for tournament state management
class TournamentNotifier extends StateNotifier<AsyncValue<List<Tournament>>> {
  final TournamentRepository _repository;

  TournamentNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadActiveTournaments();
  }

  Future<void> _loadActiveTournaments() async {
    try {
      state = const AsyncValue.loading();
      final tournaments = await _repository.fetchActiveTournaments();
      state = AsyncValue.data(tournaments);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadActiveTournaments();
  }

  Future<Tournament> convertPoolToTournament(
    String poolId,
    TournamentCreateRequest request,
  ) async {
    final tournament = await _repository.convertPoolToTournament(poolId, request);
    // Refresh the list to include the new tournament
    await refresh();
    return tournament;
  }

  Future<Tournament> startTournament(String tournamentId) async {
    final tournament = await _repository.startTournament(tournamentId);
    // Refresh to update status
    await refresh();
    return tournament;
  }
}

// Tournament State Notifier Provider
final tournamentNotifierProvider = StateNotifierProvider<TournamentNotifier, AsyncValue<List<Tournament>>>((ref) {
  return TournamentNotifier(ref.read(tournamentRepositoryProvider));
});

// Filtered tournament providers
final readyTournamentsProvider = Provider<AsyncValue<List<Tournament>>>((ref) {
  return ref.watch(activeTournamentsProvider).when(
    data: (tournaments) {
      final readyTournaments = tournaments.where((t) => t.isReady).toList();
      return AsyncValue.data(readyTournaments);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final activeTournamentsOnlyProvider = Provider<AsyncValue<List<Tournament>>>((ref) {
  return ref.watch(activeTournamentsProvider).when(
    data: (tournaments) {
      final activeTournaments = tournaments.where((t) => t.isActive).toList();
      return AsyncValue.data(activeTournaments);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final completedTournamentsProvider = Provider<AsyncValue<List<Tournament>>>((ref) {
  return ref.watch(allTournamentsProvider).when(
    data: (tournaments) {
      final completedTournaments = tournaments.where((t) => t.isCompleted).toList();
      return AsyncValue.data(completedTournaments);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Tournament search provider
final tournamentSearchProvider = StateProvider<String>((ref) => '');

final filteredTournamentsProvider = Provider<AsyncValue<List<Tournament>>>((ref) {
  final searchQuery = ref.watch(tournamentSearchProvider).toLowerCase();
  
  return ref.watch(activeTournamentsProvider).when(
    data: (tournaments) {
      if (searchQuery.isEmpty) return AsyncValue.data(tournaments);
      
      final filtered = tournaments.where((tournament) {
        return tournament.title.toLowerCase().contains(searchQuery) ||
               (tournament.description?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Tournament analytics providers
final myTournamentStatsProvider = FutureProvider<TournamentStats>((ref) async {
  final myTournaments = await ref.watch(myTournamentsProvider.future);
  
  final totalTournaments = myTournaments.length;
  final activeTournaments = myTournaments.where((t) => t.isActive).length;
  final completedTournaments = myTournaments.where((t) => t.isCompleted).length;
  final wonTournaments = myTournaments.where((t) => t.isCompleted && t.myStatus == 'winner').length;
  
  return TournamentStats(
    totalTournaments: totalTournaments,
    activeTournaments: activeTournaments,
    completedTournaments: completedTournaments,
    wonTournaments: wonTournaments,
  );
});

// Helper classes
class TournamentPhaseLeaderboardParams {
  final String tournamentId;
  final String phaseId;

  const TournamentPhaseLeaderboardParams({
    required this.tournamentId,
    required this.phaseId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TournamentPhaseLeaderboardParams &&
        other.tournamentId == tournamentId &&
        other.phaseId == phaseId;
  }

  @override
  int get hashCode => tournamentId.hashCode ^ phaseId.hashCode;
}

class TournamentStats {
  final int totalTournaments;
  final int activeTournaments;
  final int completedTournaments;
  final int wonTournaments;

  const TournamentStats({
    required this.totalTournaments,
    required this.activeTournaments,
    required this.completedTournaments,
    required this.wonTournaments,
  });

  double get winRate => 
      completedTournaments > 0 ? wonTournaments / completedTournaments : 0.0;
}