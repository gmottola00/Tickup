import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/data/models/tournament.dart';
import 'package:tickup/presentation/features/tournament/tournament_provider.dart';
import 'package:tickup/presentation/widgets/loading_overlay.dart';

class TournamentDetailsPage extends ConsumerStatefulWidget {
  const TournamentDetailsPage({
    super.key,
    required this.tournamentId,
  });

  final String tournamentId;

  @override
  ConsumerState<TournamentDetailsPage> createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends ConsumerState<TournamentDetailsPage> 
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));
    final leaderboardAsync = ref.watch(tournamentLeaderboardProvider(widget.tournamentId));
    final myParticipationAsync = ref.watch(myTournamentParticipationProvider(widget.tournamentId));
    
    return Scaffold(
      body: tournamentAsync.when(
        data: (tournament) => _TournamentDetailsView(
          tournament: tournament,
          leaderboardAsync: leaderboardAsync,
          myParticipationAsync: myParticipationAsync,
          tabController: _tabController,
          onPlayPressed: () => _startGameSession(tournament),
        ),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('Errore')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text('Errore nel caricamento del torneo'),
                const SizedBox(height: 8),
                Text(error.toString()),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(tournamentProvider(widget.tournamentId)),
                  child: const Text('Riprova'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startGameSession(Tournament tournament) async {
    if (tournament.currentPhaseInfo == null) {
      _showError('Nessuna fase attiva per giocare');
      return;
    }

    if (!tournament.canParticipate) {
      _showError('Non puoi partecipare a questa fase del torneo');
      return;
    }

    try {
      _showLoadingOverlay();
      
      final controller = ref.read(tournamentControllerProvider);
      final gameSessionId = await controller.startTournamentSession(
        tournament.id,
        tournament.currentPhaseInfo!.id,
      );

      _hideLoadingOverlay();

      if (mounted) {
        // Navigate to game with tournament context
        context.push('/games/pixel-adventure', extra: {
          'tournamentId': tournament.id,
          'phaseId': tournament.currentPhaseInfo!.id,
          'gameSessionId': gameSessionId,
          'levelCode': tournament.currentPhaseInfo!.levelId,
        });
      }
    } catch (error) {
      _hideLoadingOverlay();
      _showError('Errore nell\'avvio del gioco: $error');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingOverlay(message: 'Avvio gioco...'),
    );
  }

  void _hideLoadingOverlay() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}

class _TournamentDetailsView extends StatelessWidget {
  const _TournamentDetailsView({
    required this.tournament,
    required this.leaderboardAsync,
    required this.myParticipationAsync,
    required this.tabController,
    required this.onPlayPressed,
  });

  final Tournament tournament;
  final AsyncValue<TournamentLeaderboard> leaderboardAsync;
  final AsyncValue<TournamentParticipant?> myParticipationAsync;
  final TabController tabController;
  final VoidCallback onPlayPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(tournament.title),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.8),
                    theme.colorScheme.primary,
                  ],
                ),
              ),
              child: _TournamentHeader(tournament: tournament),
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: tabController,
              tabs: const [
                Tab(text: 'Dettagli'),
                Tab(text: 'Classifica'),
                Tab(text: 'Fasi'),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: tabController,
        children: [
          _TournamentDetailsTab(
            tournament: tournament,
            myParticipationAsync: myParticipationAsync,
            onPlayPressed: onPlayPressed,
          ),
          _TournamentLeaderboardTab(
            leaderboardAsync: leaderboardAsync,
          ),
          _TournamentPhasesTab(tournament: tournament),
        ],
      ),
    );
  }
}

class _TournamentHeader extends StatelessWidget {
  const _TournamentHeader({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tournament.participantsCount} partecipanti',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      'Fase ${tournament.currentPhase}/${tournament.totalPhases}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              _TournamentStatusBadge(status: tournament.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _TournamentStatusBadge extends StatelessWidget {
  const _TournamentStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    String label;

    switch (status.toLowerCase()) {
      case 'ready':
        backgroundColor = Colors.blue;
        label = 'Pronto';
        break;
      case 'active':
        backgroundColor = Colors.green;
        label = 'In corso';
        break;
      case 'completed':
        backgroundColor = Colors.purple;
        label = 'Completato';
        break;
      default:
        backgroundColor = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TournamentDetailsTab extends StatelessWidget {
  const _TournamentDetailsTab({
    required this.tournament,
    required this.myParticipationAsync,
    required this.onPlayPressed,
  });

  final Tournament tournament;
  final AsyncValue<TournamentParticipant?> myParticipationAsync;
  final VoidCallback onPlayPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tournament.description != null) ...[
            Text(
              'Descrizione',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(tournament.description!),
            const SizedBox(height: 24),
          ],

          _TournamentProgressCard(tournament: tournament),
          
          const SizedBox(height: 16),

          if (tournament.currentPhaseInfo != null)
            _CurrentPhaseCard(
              phase: tournament.currentPhaseInfo!,
              tournament: tournament,
            ),

          const SizedBox(height: 16),

          myParticipationAsync.when(
            data: (participation) => _MyParticipationCard(
              participation: participation,
              tournament: tournament,
              onPlayPressed: onPlayPressed,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _TournamentProgressCard extends StatelessWidget {
  const _TournamentProgressCard({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progresso Torneo',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fase ${tournament.currentPhase}/${tournament.totalPhases}'),
                Text('${(tournament.progressPercentage * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: tournament.progressPercentage),
          ],
        ),
      ),
    );
  }
}

class _CurrentPhaseCard extends StatelessWidget {
  const _CurrentPhaseCard({
    required this.phase,
    required this.tournament,
  });

  final TournamentPhase phase;
  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeRemaining = tournament.timeRemaining;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fase Attuale: ${phase.title}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            if (phase.description != null) ...[
              const SizedBox(height: 8),
              Text(phase.description!),
            ],
            
            const SizedBox(height: 12),
            
            Text(
              'Regole di eliminazione:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(phase.eliminationRuleDescription),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text('${phase.participantsCount} partecipanti'),
                const Spacer(),
                if (timeRemaining != null) ...[
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(_formatTimeRemaining(timeRemaining)),
                ] else if (tournament.isPhaseExpired) ...[
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Scaduta',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}g ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

class _MyParticipationCard extends StatelessWidget {
  const _MyParticipationCard({
    required this.participation,
    required this.tournament,
    required this.onPlayPressed,
  });

  final TournamentParticipant? participation;
  final Tournament tournament;
  final VoidCallback onPlayPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (participation == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Non stai partecipando a questo torneo',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La Mia Partecipazione',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Miglior punteggio:'),
                Text(
                  participation!.bestScore.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            if (participation!.bestTimeSeconds != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Miglior tempo:'),
                  Text(
                    '${participation!.bestTimeSeconds}s',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Partite giocate:'),
                Text(
                  participation!.sessionsCount.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (tournament.canParticipate && tournament.currentPhaseInfo != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onPlayPressed,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Gioca'),
                ),
              )
            else if (tournament.isEliminated)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sei stato eliminato da questo torneo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TournamentLeaderboardTab extends StatelessWidget {
  const _TournamentLeaderboardTab({
    required this.leaderboardAsync,
  });

  final AsyncValue<TournamentLeaderboard> leaderboardAsync;

  @override
  Widget build(BuildContext context) {
    return leaderboardAsync.when(
      data: (leaderboard) {
        if (leaderboard.participants.isEmpty) {
          return const Center(
            child: Text('Nessun partecipante nella classifica'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: leaderboard.participants.length,
          itemBuilder: (context, index) {
            final participant = leaderboard.participants[index];
            return _LeaderboardItem(
              participant: participant,
              position: index + 1,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text('Errore nel caricamento classifica'),
            const SizedBox(height: 8),
            Text(error.toString()),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  const _LeaderboardItem({
    required this.participant,
    required this.position,
  });

  final TournamentParticipant participant;
  final int position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color? backgroundColor;
    Widget? leadingIcon;

    if (position == 1) {
      backgroundColor = Colors.amber.withOpacity(0.1);
      leadingIcon = const Icon(Icons.emoji_events, color: Colors.amber);
    } else if (position == 2) {
      backgroundColor = Colors.grey.withOpacity(0.1);
      leadingIcon = const Icon(Icons.emoji_events, color: Colors.grey);
    } else if (position == 3) {
      backgroundColor = Colors.orange.withOpacity(0.1);
      leadingIcon = const Icon(Icons.emoji_events, color: Colors.orange);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: leadingIcon ?? CircleAvatar(
          child: Text(position.toString()),
        ),
        title: Text('Giocatore ${participant.playerId}'), // TODO: Replace with actual player name
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Punteggio: ${participant.bestScore}'),
            if (participant.bestTimeSeconds != null)
              Text('Tempo: ${participant.bestTimeSeconds}s'),
          ],
        ),
        trailing: participant.qualified
            ? Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              )
            : participant.eliminatedAt != null
                ? Icon(
                    Icons.cancel,
                    color: theme.colorScheme.error,
                  )
                : null,
      ),
    );
  }
}

class _TournamentPhasesTab extends StatelessWidget {
  const _TournamentPhasesTab({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    if (tournament.phases.isEmpty) {
      return const Center(
        child: Text('Nessuna fase configurata'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournament.phases.length,
      itemBuilder: (context, index) {
        final phase = tournament.phases[index];
        final isCurrentPhase = phase.phaseNumber == tournament.currentPhase;
        
        return _PhaseCard(
          phase: phase,
          isCurrentPhase: isCurrentPhase,
        );
      },
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.phase,
    required this.isCurrentPhase,
  });

  final TournamentPhase phase;
  final bool isCurrentPhase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCurrentPhase ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Fase ${phase.phaseNumber}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _PhaseStatusChip(status: phase.status),
                if (isCurrentPhase) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ATTUALE',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              phase.title,
              style: theme.textTheme.titleMedium,
            ),
            if (phase.description != null) ...[
              const SizedBox(height: 4),
              Text(phase.description!),
            ],
            const SizedBox(height: 12),
            Text(phase.eliminationRuleDescription),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people_outline, size: 16),
                const SizedBox(width: 4),
                Text('${phase.participantsCount} partecipanti'),
                if (phase.isCompleted) ...[
                  const Spacer(),
                  Icon(Icons.done, size: 16),
                  const SizedBox(width: 4),
                  Text('${phase.qualifiedCount} qualificati'),
                ],
              ],
            ),
            if (phase.deadlineAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 4),
                  Text('Durata: ${phase.durationHours}h'),
                  if (phase.isActive && !phase.isExpired) ...[
                    const Spacer(),
                    Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text(_formatTimeRemaining(phase.timeRemaining!)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}g ${duration.inHours.remainder(24)}h rimanenti';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m rimanenti';
    } else {
      return '${duration.inMinutes}m rimanenti';
    }
  }
}

class _PhaseStatusChip extends StatelessWidget {
  const _PhaseStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    String label;

    switch (status.toLowerCase()) {
      case 'scheduled':
        backgroundColor = Colors.grey;
        label = 'Programmata';
        break;
      case 'active':
        backgroundColor = Colors.green;
        label = 'Attiva';
        break;
      case 'completed':
        backgroundColor = Colors.blue;
        label = 'Completata';
        break;
      default:
        backgroundColor = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: backgroundColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: backgroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}