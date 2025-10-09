import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/prize_image.dart';
import 'package:tickup/data/repositories/prize_image_repository.dart';

final prizeImageRepositoryProvider =
    Provider<PrizeImageRepository>((ref) => PrizeImageRepository());

final prizeImagesProvider =
    FutureProvider.family<List<PrizeImage>, String>((ref, prizeId) async {
  return ref.read(prizeImageRepositoryProvider).list(prizeId);
});

class PrizeImagesController
    extends StateNotifier<AsyncValue<List<PrizeImage>>> {
  PrizeImagesController(this.ref, this.prizeId)
      : super(const AsyncLoading()) {
    _load();
  }

  final Ref ref;
  final String prizeId;

  Future<void> _load() async {
    try {
      final items = await ref.read(prizeImageRepositoryProvider).list(prizeId);
      state = AsyncData(items);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<int> addImages(List<PrizeImageCreate> dtos) async {
    final repo = ref.read(prizeImageRepositoryProvider);
    final before = state.valueOrNull ?? const <PrizeImage>[];
    state = AsyncData(before);
    try {
      int ok = 0;
      for (final dto in dtos) {
        try {
          await repo.create(prizeId, dto);
          ok++;
        } catch (_) {
          // continue to try others
        }
      }
      await _load();
      return ok;
    } catch (e, st) {
      state = AsyncError(e, st);
      await _load();
      rethrow;
    }
  }

  Future<void> setCover(String imageId) async {
    final repo = ref.read(prizeImageRepositoryProvider);
    try {
      await repo.setCover(prizeId, imageId);
      await _load();
    } catch (e, st) {
      state = AsyncError(e, st);
      await _load();
    }
  }

  Future<void> reorder(List<PrizeImageReorderItem> items) async {
    final repo = ref.read(prizeImageRepositoryProvider);
    try {
      final list = await repo.reorder(prizeId, items);
      state = AsyncData(list);
    } catch (e, st) {
      state = AsyncError(e, st);
      await _load();
    }
  }

  Future<void> delete(String imageId) async {
    final repo = ref.read(prizeImageRepositoryProvider);
    try {
      await repo.delete(prizeId, imageId);
      await _load();
    } catch (e, st) {
      state = AsyncError(e, st);
      await _load();
    }
  }
}

final prizeImagesControllerProvider = StateNotifierProvider.family<
    PrizeImagesController, AsyncValue<List<PrizeImage>>, String>(
  (ref, prizeId) => PrizeImagesController(ref, prizeId),
);
