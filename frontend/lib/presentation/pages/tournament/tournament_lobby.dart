import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/data/models/tournament.dart';
import 'package:tickup/presentation/features/tournament/tournament_provider.dart';

class TournamentLobbyPage extends ConsumerWidget {
  const TournamentLobbyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(activeTournamentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tornei Attivi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(activeTournamentsProvider),
          ),
        ],
      ),
      body: tournamentsAsync.when(
        data: (tournaments) {
          if (tournaments.isEmpty) {
            return const _EmptyTournamentsView();
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(activeTournamentsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tournaments.length,
              itemBuilder: (context, index) {
                final tournament = tournaments[index];
                return _TournamentCard(
                  tournament: tournament,
                  onTap: () => context.push('/tournaments/${tournament.id}'),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Errore nel caricamento tornei',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(activeTournamentsProvider),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({
    required this.tournament,
    required this.onTap,
  });

  final Tournament tournament;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tournament.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _TournamentStatusChip(status: tournament.status),
                ],
              ),
              
              if (tournament.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  tournament.description!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              _TournamentProgressBar(tournament: tournament),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${tournament.participantsCount} partecipanti',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Fase ${tournament.currentPhase}/${tournament.totalPhases}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              
              if (tournament.currentPhase > 0 && tournament.currentPhaseDeadline != null) ...[
                const SizedBox(height: 8),
                _TimeRemainingWidget(deadline: tournament.currentPhaseDeadline!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TournamentStatusChip extends StatelessWidget {
  const _TournamentStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'ready':
        backgroundColor = theme.colorScheme.primary.withOpacity(0.1);
        textColor = theme.colorScheme.primary;
        label = 'Pronto';
        break;
      case 'active':
        backgroundColor = theme.colorScheme.secondary.withOpacity(0.1);
        textColor = theme.colorScheme.secondary;
        label = 'In corso';
        break;
      case 'completed':
        backgroundColor = theme.colorScheme.tertiary.withOpacity(0.1);
        textColor = theme.colorScheme.tertiary;
        label = 'Completato';
        break;
      default:
        backgroundColor = theme.colorScheme.outline.withOpacity(0.1);
        textColor = theme.colorScheme.onSurfaceVariant;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TournamentProgressBar extends StatelessWidget {
  const _TournamentProgressBar({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = tournament.totalPhases > 0 
        ? (tournament.currentPhase / tournament.totalPhases).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso torneo',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '${(progress * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
        ),
      ],
    );
  }
}

class _TimeRemainingWidget extends StatelessWidget {
  const _TimeRemainingWidget({required this.deadline});

  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final remaining = deadline.difference(now);
    
    if (remaining.isNegative) {
      return Row(
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            'Fase scaduta',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    String timeText;
    if (remaining.inDays > 0) {
      timeText = '${remaining.inDays}g ${remaining.inHours.remainder(24)}h rimanenti';
    } else if (remaining.inHours > 0) {
      timeText = '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m rimanenti';
    } else {
      timeText = '${remaining.inMinutes}m rimanenti';
    }

    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          timeText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EmptyTournamentsView extends StatelessWidget {
  const _EmptyTournamentsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun torneo attivo',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'I tornei appariranno qui quando i pool\nraggiungono il numero massimo di partecipanti',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/pools'),
            child: const Text('Esplora Pool'),
          ),
        ],
      ),
    );
  }
}