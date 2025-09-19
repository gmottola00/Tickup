import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/data/models/wallet.dart';
import 'package:tickup/presentation/features/wallet/wallet_provider.dart';
import 'package:tickup/presentation/routing/app_route.dart';

class WalletOverviewPage extends ConsumerWidget {
  const WalletOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(myWalletProvider);
    final ledgerAsync = ref.watch(walletLedgerProvider);

    Future<void> refresh() async {
      ref.invalidate(myWalletProvider);
      ref.invalidate(walletLedgerProvider);
      await Future.wait([
        ref.read(myWalletProvider.future),
        ref.read(walletLedgerProvider.future),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Il mio wallet'),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: walletAsync.when(
          loading: () => const _WalletOverviewLoading(),
          error: (error, _) => _WalletOverviewError(
            error: error.toString(),
            onRetry: () {
              ref.invalidate(myWalletProvider);
              ref.invalidate(walletLedgerProvider);
            },
          ),
          data: (wallet) {
            return ledgerAsync.when(
              loading: () => const _WalletOverviewLoading(),
              error: (error, _) => _WalletOverviewError(
                error: error.toString(),
                onRetry: () {
                  ref.invalidate(walletLedgerProvider);
                },
              ),
              data: (ledger) => _WalletOverviewContent(
                wallet: wallet,
                ledger: ledger,
                onCreateTopup: () async {
                  final created = await context.push(AppRoute.walletTopupCreate);
                  if (created == true) {
                    ref.invalidate(myWalletProvider);
                    ref.invalidate(walletLedgerProvider);
                    ref.invalidate(walletTopupsProvider);
                  }
                },
                onViewTopups: () {
                  context.push(AppRoute.walletTopups);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WalletOverviewLoading extends StatelessWidget {
  const _WalletOverviewLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _WalletOverviewError extends StatelessWidget {
  const _WalletOverviewError({required this.error, required this.onRetry});
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

class _WalletOverviewContent extends StatelessWidget {
  const _WalletOverviewContent({
    required this.wallet,
    required this.ledger,
    required this.onCreateTopup,
    required this.onViewTopups,
  });
  final WalletAccount wallet;
  final WalletLedgerList ledger;
  final Future<void> Function() onCreateTopup;
  final VoidCallback onViewTopups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceEuro = _formatEuro(wallet.balanceCents);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo disponibile',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '€ $balanceEuro',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.currency_exchange, size: 16),
                      label: Text(wallet.currency),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Chip(
                      avatar: const Icon(Icons.verified_user, size: 16),
                      label: Text('Stato: ${wallet.status.value}'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    if (wallet.createdAt != null)
                      Chip(
                        avatar: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          'Creato il ${_formatDate(wallet.createdAt!)}',
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await onCreateTopup();
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Ricarica wallet'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewTopups,
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Storico ricariche'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Movimenti recenti',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (ledger.items.isEmpty)
          const _WalletLedgerEmpty()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ledger.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = ledger.items[index];
              return _WalletLedgerTile(entry: entry);
            },
          ),
      ],
    );
  }
}

class _WalletLedgerEmpty extends StatelessWidget {
  const _WalletLedgerEmpty();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 48),
            const SizedBox(height: 12),
            Text(
              'Nessun movimento registrato',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletLedgerTile extends StatelessWidget {
  const _WalletLedgerTile({required this.entry});
  final WalletLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = entry.direction == WalletLedgerDirection.credit;
    final sign = isCredit ? '+' : '-';
    final amount = '$sign€ ${_formatEuro(entry.amountCents)}';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isCredit
                  ? Colors.green.withOpacity(0.12)
                  : Colors.red.withOpacity(0.12),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _reasonLabel(entry.reason),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stato: ${entry.status.value}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (entry.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(entry.createdAt!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amount,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isCredit ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatEuro(int cents) {
  return (cents / 100).toStringAsFixed(2);
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _reasonLabel(WalletLedgerReason reason) {
  switch (reason) {
    case WalletLedgerReason.topup:
      return 'Ricarica wallet';
    case WalletLedgerReason.ticketPurchase:
      return 'Acquisto ticket';
    case WalletLedgerReason.refund:
      return 'Rimborso';
    case WalletLedgerReason.prizePayout:
      return 'Premio';
    case WalletLedgerReason.adjustment:
      return 'Rettifica';
  }
}
