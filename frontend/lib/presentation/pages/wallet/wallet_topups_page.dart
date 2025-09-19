import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/wallet.dart';
import 'package:tickup/presentation/features/wallet/wallet_provider.dart';

class WalletTopupsPage extends ConsumerWidget {
  const WalletTopupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topupsAsync = ref.watch(walletTopupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Le mie ricariche'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletTopupsProvider);
          await ref.read(walletTopupsProvider.future);
        },
        child: topupsAsync.when(
          loading: () => const _WalletTopupsLoading(),
          error: (error, _) => _WalletTopupsError(
            error: error.toString(),
            onRetry: () => ref.invalidate(walletTopupsProvider),
          ),
          data: (items) => _WalletTopupsContent(items: items, ref: ref),
        ),
      ),
    );
  }
}

class _WalletTopupsLoading extends StatelessWidget {
  const _WalletTopupsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _WalletTopupSkeleton(),
    );
  }
}

class _WalletTopupSkeleton extends StatelessWidget {
  const _WalletTopupSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const SizedBox(height: 88),
    );
  }
}

class _WalletTopupsError extends StatelessWidget {
  const _WalletTopupsError({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text('Errore: $error'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Riprova'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletTopupsContent extends StatelessWidget {
  const _WalletTopupsContent({required this.items, required this.ref});
  final List<WalletTopupRequest> items;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _WalletTopupsEmpty();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _WalletTopupCard(
        topup: items[index],
        ref: ref,
      ),
    );
  }
}

class _WalletTopupsEmpty extends StatelessWidget {
  const _WalletTopupsEmpty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 64),
                const SizedBox(height: 12),
                Text(
                  'Non hai ancora richieste di ricarica',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Avvia una ricarica per vederla qui',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletTopupCard extends StatefulWidget {
  const _WalletTopupCard({required this.topup, required this.ref});
  final WalletTopupRequest topup;
  final WidgetRef ref;

  @override
  State<_WalletTopupCard> createState() => _WalletTopupCardState();
}

class _WalletTopupCardState extends State<_WalletTopupCard> {
  bool _completing = false;

  bool get _canComplete {
    final status = widget.topup.status;
    return status == WalletTopupStatus.created ||
        status == WalletTopupStatus.processing;
  }

  Future<void> _completeTopup(BuildContext context) async {
    if (!_canComplete || _completing) return;
    setState(() => _completing = true);
    final messenger = ScaffoldMessenger.of(context);
    final txnId = widget.topup.providerTxnId?.isNotEmpty == true
        ? widget.topup.providerTxnId
        : 'MOCK-${DateTime.now().millisecondsSinceEpoch}';
    try {
      await widget.ref.read(walletRepositoryProvider).completeTopup(
            widget.topup.topupId,
            WalletTopupCompleteInput(providerTxnId: txnId),
          );
      widget.ref.invalidate(walletTopupsProvider);
      widget.ref.invalidate(myWalletProvider);
      widget.ref.invalidate(walletLedgerProvider);
      await Future.wait([
        widget.ref.read(walletTopupsProvider.future),
        widget.ref.read(myWalletProvider.future),
      ]);
      messenger.showSnackBar(
        const SnackBar(content: Text('Ricarica completata')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Errore nel completamento: $error')),
      );
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topup = widget.topup;
    final amount = '€ ${_formatEuro(topup.amountCents)}';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    (topup.provider.isNotEmpty ? topup.provider[0] : '?')
                        .toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topup.provider,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stato: ${topup.status.value}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  amount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (topup.providerTxnId != null)
                  Chip(
                    avatar: const Icon(Icons.numbers, size: 16),
                    label: Text('Txn: ${topup.providerTxnId}'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                Chip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: Text('Creato il ${_formatDate(topup.createdAt)}'),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (topup.completedAt != null)
                  Chip(
                    avatar: const Icon(Icons.check_circle, size: 16),
                    label: Text('Completato il ${_formatDate(topup.completedAt!)}'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            if (_canComplete) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _completing ? null : () => _completeTopup(context),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_completing ? 'Completamento...' : 'Completa ricarica (mock)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatEuro(int cents) {
  return (cents / 100).toStringAsFixed(2);
}

String _formatDate(DateTime? date) {
  if (date == null) return '--';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
