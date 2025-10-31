class Tournament {
  final String id;
  final String poolId;
  final String title;
  final String? description;
  final String status; // ready, active, completed, cancelled
  final int totalPhases;
  final int currentPhase;
  final DateTime? scheduledStartAt;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int participantsCount;
  final TournamentPhase? currentPhaseInfo;
  final List<TournamentPhase> phases;
  final String? myStatus; // qualified, eliminated, active, not_participating
  final DateTime? currentPhaseDeadline;

  const Tournament({
    required this.id,
    required this.poolId,
    required this.title,
    this.description,
    required this.status,
    required this.totalPhases,
    required this.currentPhase,
    this.scheduledStartAt,
    required this.createdAt,
    this.completedAt,
    required this.participantsCount,
    this.currentPhaseInfo,
    this.phases = const [],
    this.myStatus,
    this.currentPhaseDeadline,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id']?.toString() ?? '',
      poolId: json['pool_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'ready',
      totalPhases: (json['total_phases'] as num?)?.toInt() ?? 0,
      currentPhase: (json['current_phase'] as num?)?.toInt() ?? 0,
      scheduledStartAt: json['scheduled_start_at'] != null
          ? DateTime.tryParse(json['scheduled_start_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      participantsCount: (json['participants_count'] as num?)?.toInt() ?? 0,
      currentPhaseInfo: json['current_phase_info'] != null
          ? TournamentPhase.fromJson(json['current_phase_info'] as Map<String, dynamic>)
          : null,
      phases: json['phases'] != null
          ? (json['phases'] as List)
              .map((phase) => TournamentPhase.fromJson(phase as Map<String, dynamic>))
              .toList()
          : [],
      myStatus: json['my_status']?.toString(),
      currentPhaseDeadline: json['current_phase_deadline'] != null
          ? DateTime.tryParse(json['current_phase_deadline'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pool_id': poolId,
      'title': title,
      'description': description,
      'status': status,
      'total_phases': totalPhases,
      'current_phase': currentPhase,
      'scheduled_start_at': scheduledStartAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'participants_count': participantsCount,
      'current_phase_info': currentPhaseInfo?.toJson(),
      'phases': phases.map((phase) => phase.toJson()).toList(),
      'my_status': myStatus,
      'current_phase_deadline': currentPhaseDeadline?.toIso8601String(),
    };
  }

  Tournament copyWith({
    String? id,
    String? poolId,
    String? title,
    String? description,
    String? status,
    int? totalPhases,
    int? currentPhase,
    DateTime? scheduledStartAt,
    DateTime? createdAt,
    DateTime? completedAt,
    int? participantsCount,
    TournamentPhase? currentPhaseInfo,
    List<TournamentPhase>? phases,
    String? myStatus,
    DateTime? currentPhaseDeadline,
  }) {
    return Tournament(
      id: id ?? this.id,
      poolId: poolId ?? this.poolId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      totalPhases: totalPhases ?? this.totalPhases,
      currentPhase: currentPhase ?? this.currentPhase,
      scheduledStartAt: scheduledStartAt ?? this.scheduledStartAt,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      participantsCount: participantsCount ?? this.participantsCount,
      currentPhaseInfo: currentPhaseInfo ?? this.currentPhaseInfo,
      phases: phases ?? this.phases,
      myStatus: myStatus ?? this.myStatus,
      currentPhaseDeadline: currentPhaseDeadline ?? this.currentPhaseDeadline,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tournament && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Tournament(id: $id, title: $title, status: $status, phase: $currentPhase/$totalPhases)';
  }

  // Utility getters
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isReady => status == 'ready';
  bool get isCancelled => status == 'cancelled';

  bool get canParticipate => myStatus == 'active' || myStatus == 'qualified';
  bool get isEliminated => myStatus == 'eliminated';
  bool get isQualified => myStatus == 'qualified';

  double get progressPercentage => 
      totalPhases > 0 ? (currentPhase / totalPhases).clamp(0.0, 1.0) : 0.0;

  Duration? get timeRemaining {
    if (currentPhaseDeadline == null) return null;
    final remaining = currentPhaseDeadline!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  bool get isPhaseExpired {
    if (currentPhaseDeadline == null) return false;
    return DateTime.now().isAfter(currentPhaseDeadline!);
  }
}

class TournamentPhase {
  final String id;
  final String tournamentId;
  final int phaseNumber;
  final String gameId;
  final String? levelId;
  final String title;
  final String? description;
  final int durationHours;
  final Map<String, dynamic> eliminationRule;
  final int? minScore;
  final int? maxTimeSeconds;
  final String status; // scheduled, active, completed, cancelled
  final DateTime? startedAt;
  final DateTime? deadlineAt;
  final int participantsCount;
  final int qualifiedCount;

  const TournamentPhase({
    required this.id,
    required this.tournamentId,
    required this.phaseNumber,
    required this.gameId,
    this.levelId,
    required this.title,
    this.description,
    required this.durationHours,
    this.eliminationRule = const {},
    this.minScore,
    this.maxTimeSeconds,
    required this.status,
    this.startedAt,
    this.deadlineAt,
    required this.participantsCount,
    required this.qualifiedCount,
  });

  factory TournamentPhase.fromJson(Map<String, dynamic> json) {
    return TournamentPhase(
      id: json['id']?.toString() ?? '',
      tournamentId: json['tournament_id']?.toString() ?? '',
      phaseNumber: (json['phase_number'] as num?)?.toInt() ?? 0,
      gameId: json['game_id']?.toString() ?? '',
      levelId: json['level_id']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      durationHours: (json['duration_hours'] as num?)?.toInt() ?? 72,
      eliminationRule: json['elimination_rule'] as Map<String, dynamic>? ?? {},
      minScore: (json['min_score'] as num?)?.toInt(),
      maxTimeSeconds: (json['max_time_seconds'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'scheduled',
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString())
          : null,
      deadlineAt: json['deadline_at'] != null
          ? DateTime.tryParse(json['deadline_at'].toString())
          : null,
      participantsCount: (json['participants_count'] as num?)?.toInt() ?? 0,
      qualifiedCount: (json['qualified_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'phase_number': phaseNumber,
      'game_id': gameId,
      'level_id': levelId,
      'title': title,
      'description': description,
      'duration_hours': durationHours,
      'elimination_rule': eliminationRule,
      'min_score': minScore,
      'max_time_seconds': maxTimeSeconds,
      'status': status,
      'started_at': startedAt?.toIso8601String(),
      'deadline_at': deadlineAt?.toIso8601String(),
      'participants_count': participantsCount,
      'qualified_count': qualifiedCount,
    };
  }

  // Utility getters
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isScheduled => status == 'scheduled';

  Duration? get timeRemaining {
    if (deadlineAt == null) return null;
    final remaining = deadlineAt!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  bool get isExpired {
    if (deadlineAt == null) return false;
    return DateTime.now().isAfter(deadlineAt!);
  }

  String get eliminationRuleDescription {
    final type = eliminationRule['type'] as String?;
    final value = eliminationRule['value'];

    switch (type) {
      case 'top_percentage':
        return 'Passa il top $value% dei giocatori';
      case 'min_score':
        return 'Punteggio minimo: $value punti';
      case 'max_time':
        return 'Tempo massimo: ${value}s';
      case 'combined':
        final minScore = eliminationRule['min_score'];
        final timePercentage = eliminationRule['time_percentage'];
        return 'Min $minScore punti + top $timePercentage% per tempo';
      default:
        return 'Regole personalizzate';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TournamentPhase && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class TournamentParticipant {
  final String id;
  final String tournamentId;
  final String phaseId;
  final String playerId;
  final bool qualified;
  final int bestScore;
  final int? bestTimeSeconds;
  final int sessionsCount;
  final DateTime? lastPlayedAt;
  final DateTime? eliminatedAt;
  final DateTime? qualifiedAt;

  const TournamentParticipant({
    required this.id,
    required this.tournamentId,
    required this.phaseId,
    required this.playerId,
    required this.qualified,
    required this.bestScore,
    this.bestTimeSeconds,
    required this.sessionsCount,
    this.lastPlayedAt,
    this.eliminatedAt,
    this.qualifiedAt,
  });

  factory TournamentParticipant.fromJson(Map<String, dynamic> json) {
    return TournamentParticipant(
      id: json['id']?.toString() ?? '',
      tournamentId: json['tournament_id']?.toString() ?? '',
      phaseId: json['phase_id']?.toString() ?? '',
      playerId: json['player_id']?.toString() ?? '',
      qualified: json['qualified'] as bool? ?? false,
      bestScore: (json['best_score'] as num?)?.toInt() ?? 0,
      bestTimeSeconds: (json['best_time_seconds'] as num?)?.toInt(),
      sessionsCount: (json['sessions_count'] as num?)?.toInt() ?? 0,
      lastPlayedAt: json['last_played_at'] != null
          ? DateTime.tryParse(json['last_played_at'].toString())
          : null,
      eliminatedAt: json['eliminated_at'] != null
          ? DateTime.tryParse(json['eliminated_at'].toString())
          : null,
      qualifiedAt: json['qualified_at'] != null
          ? DateTime.tryParse(json['qualified_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'phase_id': phaseId,
      'player_id': playerId,
      'qualified': qualified,
      'best_score': bestScore,
      'best_time_seconds': bestTimeSeconds,
      'sessions_count': sessionsCount,
      'last_played_at': lastPlayedAt?.toIso8601String(),
      'eliminated_at': eliminatedAt?.toIso8601String(),
      'qualified_at': qualifiedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TournamentParticipant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class TournamentLeaderboard {
  final String tournamentId;
  final String? phaseId;
  final List<TournamentParticipant> participants;

  const TournamentLeaderboard({
    required this.tournamentId,
    this.phaseId,
    required this.participants,
  });

  factory TournamentLeaderboard.fromJson(Map<String, dynamic> json) {
    return TournamentLeaderboard(
      tournamentId: json['tournament_id']?.toString() ?? '',
      phaseId: json['phase_id']?.toString(),
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => TournamentParticipant.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tournament_id': tournamentId,
      'phase_id': phaseId,
      'participants': participants.map((p) => p.toJson()).toList(),
    };
  }
}

class TournamentCreateRequest {
  final String title;
  final String? description;
  final List<TournamentPhaseConfig> phases;
  final DateTime? scheduledStart;

  const TournamentCreateRequest({
    required this.title,
    this.description,
    required this.phases,
    this.scheduledStart,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'phases': phases.map((p) => p.toJson()).toList(),
      'scheduled_start': scheduledStart?.toIso8601String(),
    };
  }
}

class TournamentPhaseConfig {
  final String gameCode;
  final String? levelCode;
  final int durationHours;
  final Map<String, dynamic> eliminationRule;

  const TournamentPhaseConfig({
    required this.gameCode,
    this.levelCode,
    required this.durationHours,
    required this.eliminationRule,
  });

  Map<String, dynamic> toJson() {
    return {
      'game_code': gameCode,
      'level_code': levelCode,
      'duration_hours': durationHours,
      'elimination_rule': eliminationRule,
    };
  }
}