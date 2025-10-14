import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/data/models/like_status.dart';
import 'package:tickup/presentation/features/pool/pool_provider.dart';

LikeStatus _initialLike(Ref ref, String poolId) {
  LikeStatus? fromAsync(AsyncValue<List<RafflePool>> asyncValue) {
    return asyncValue.maybeWhen(
      data: (items) {
        for (final pool in items) {
          if (pool.poolId == poolId) {
            return LikeStatus(likes: pool.likes, likedByMe: pool.likedByMe);
          }
        }
        return null;
      },
      orElse: () => null,
    );
  }

  final candidates = <AsyncValue<List<RafflePool>>>[
    ref.read(poolsProvider),
    ref.read(likedPoolsProvider),
    ref.read(myPoolsProvider),
  ];

  for (final candidate in candidates) {
    final match = fromAsync(candidate);
    if (match != null) return match;
  }

  return const LikeStatus(likes: 0, likedByMe: false);
}

class PoolLikeController extends StateNotifier<LikeStatus> {
  PoolLikeController(this.ref, this.poolId)
      : super(_initialLike(ref, poolId)) {
    // Ensure we fetch the authoritative like status on first use
    // so the heart icon reflects persisted state after app restart.
    _loadFromServerOnce();
  }

  final Ref ref;
  final String poolId;
  bool _loaded = false;

  Future<void> _loadFromServerOnce() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final repo = ref.read(raffleRepositoryProvider);
      final res = await repo.fetchLikeStatus(poolId);
      state = res;
    } catch (_) {
      // ignore network errors; keep current optimistic/local state
    }
  }

  Future<void> toggle() async {
    final repo = ref.read(raffleRepositoryProvider);
    final before = state;
    final optimistic = LikeStatus(
      likes: before.likedByMe ? max(before.likes - 1, 0) : (before.likes + 1),
      likedByMe: !before.likedByMe,
    );
    state = optimistic;
    try {
      final res = before.likedByMe
          ? await repo.unlikePool(poolId)
          : await repo.likePool(poolId);
      state = res;
    } catch (_) {
      state = before;
    }
  }
}

final poolLikeProvider = StateNotifierProvider.family<PoolLikeController, LikeStatus, String>(
  (ref, poolId) => PoolLikeController(ref, poolId),
);
