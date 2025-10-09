import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/like_status.dart';
import 'package:tickup/presentation/features/pool/pool_provider.dart';

class PoolLikeParams {
  const PoolLikeParams({required this.poolId, required this.initial});

  final String poolId;
  final LikeStatus initial;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PoolLikeParams &&
        other.poolId == poolId &&
        other.initial.likes == initial.likes &&
        other.initial.likedByMe == initial.likedByMe;
  }

  @override
  int get hashCode => Object.hash(poolId, initial.likes, initial.likedByMe);
}

class PoolLikeController extends StateNotifier<LikeStatus> {
  PoolLikeController(this.ref, this.params) : super(params.initial);

  final PoolLikeParams params;
  final Ref ref;

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
          ? await repo.unlikePool(params.poolId)
          : await repo.likePool(params.poolId);
      state = res;
    } catch (_) {
      state = before;
    }
  }
}

final poolLikeProvider = StateNotifierProvider.family<PoolLikeController, LikeStatus, PoolLikeParams>(
  (ref, params) => PoolLikeController(ref, params),
);
