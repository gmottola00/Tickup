import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/like_status.dart';
import 'package:tickup/presentation/features/pool/pool_provider.dart';

class PoolLikeController extends StateNotifier<LikeStatus?> {
  PoolLikeController(this.ref, this.poolId) : super(null) {
    _load();
  }

  final Ref ref;
  final String poolId;

  Future<void> _load() async {
    try {
      final status = await ref.read(raffleRepositoryProvider).fetchLikeStatus(poolId);
      state = status;
    } catch (_) {
      // keep null; UI will rely on pool defaults
    }
  }

  Future<void> toggle() async {
    final repo = ref.read(raffleRepositoryProvider);
    final before = state ?? const LikeStatus(likes: 0, likedByMe: false);
    final optimistic = LikeStatus(
      likes: before.likedByMe ? (before.likes - 1) : (before.likes + 1),
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

final poolLikeProvider = StateNotifierProvider.family<PoolLikeController, LikeStatus?, String>(
  (ref, poolId) => PoolLikeController(ref, poolId),
);
