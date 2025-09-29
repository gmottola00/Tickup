import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/purchase.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/data/repositories/purchase_repository.dart';
import 'package:tickup/presentation/features/pool/pool_provider.dart';
import 'package:tickup/core/utils/logger.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository();
});

final myPurchasesProvider = FutureProvider<List<Purchase>>((ref) {
  return ref.read(purchaseRepositoryProvider).fetchMyPurchases();
});

final myParticipatingPoolsProvider = FutureProvider<List<RafflePool>>((ref) async {
  final purchases = await ref.watch(myPurchasesProvider.future);
  final repo = ref.read(raffleRepositoryProvider);
  final eligiblePurchases = purchases.where((purchase) {
    final isEntry = purchase.type == PurchaseType.entry;
    final isConfirmed = purchase.status == PurchaseStatus.confirmed;
    final hasWalletEntry = purchase.walletEntryId != null;
    return isEntry && isConfirmed && hasWalletEntry;
  }).toList();

  final poolIds = eligiblePurchases
      .map((purchase) => purchase.poolId)
      .where((poolId) => poolId.isNotEmpty)
      .toSet();

  if (poolIds.isEmpty) {
    return const [];
  }

  final pools = <RafflePool>[];
  for (final poolId in poolIds) {
    try {
      final pool = await repo.fetchPool(poolId);
      pools.add(pool);
    } catch (error, stackTrace) {
      Logger.error('Failed to fetch pool $poolId for my tickets',
          error: error, stackTrace: stackTrace);
    }
  }

  return pools;
});

class PoolParticipationSummary {
  PoolParticipationSummary({required this.pool, required this.purchases});

  final RafflePool pool;
  final List<Purchase> purchases;

  int get ticketsCount => purchases.length;

  int get totalAmountCents =>
      purchases.fold<int>(0, (sum, purchase) => sum + purchase.amountCents);

  DateTime? get lastPurchaseAt {
    DateTime? latest;
    for (final purchase in purchases) {
      final createdAt = purchase.createdAt;
      if (createdAt == null) continue;
      if (latest == null || createdAt.isAfter(latest)) {
        latest = createdAt;
      }
    }
    return latest;
  }
}

final myPoolParticipationSummariesProvider =
    FutureProvider<List<PoolParticipationSummary>>((ref) async {
  final purchases = await ref.watch(myPurchasesProvider.future);
  final repo = ref.read(raffleRepositoryProvider);

  final filtered = purchases.where((purchase) {
    final isEntry = purchase.type == PurchaseType.entry;
    final isConfirmed = purchase.status == PurchaseStatus.confirmed;
    final hasWalletEntry = purchase.walletEntryId != null;
    return isEntry && isConfirmed && hasWalletEntry;
  });

  if (filtered.isEmpty) {
    return const [];
  }

  final grouped = <String, List<Purchase>>{};
  for (final purchase in filtered) {
    final poolId = purchase.poolId;
    if (poolId.isEmpty) continue;
    grouped.putIfAbsent(poolId, () => <Purchase>[]).add(purchase);
  }

  if (grouped.isEmpty) {
    return const [];
  }

  final summaries = <PoolParticipationSummary>[];
  for (final entry in grouped.entries) {
    try {
      final pool = await repo.fetchPool(entry.key);
      summaries.add(
        PoolParticipationSummary(pool: pool, purchases: entry.value),
      );
    } catch (error, stackTrace) {
      Logger.error('Failed to fetch pool ${entry.key} for participation summary',
          error: error, stackTrace: stackTrace);
    }
  }

  return summaries;
});
