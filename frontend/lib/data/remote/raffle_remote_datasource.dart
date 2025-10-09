import 'package:dio/dio.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/data/models/like_status.dart';
import 'package:tickup/core/network/dio_client.dart';
import 'package:tickup/core/config/env_config.dart';

class RaffleRemoteDataSource {
  final Dio dio = DioClient().dio;

  Future<List<RafflePool>> getPools() async {
    // if (EnvConfig.isDevelopment) {
    //   return _mockPools();
    // }
    // Backend route: GET /api/v1/pools/all_pools
    final res = await dio.get('pools/all_pools');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic> ? (raw['data'] as List?) : null) ??
            <dynamic>[];
    return list
        .map((e) => RafflePool.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RafflePool>> _mockPools() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    return [
      RafflePool(
        poolId: 'pool-1',
        prizeId: 'demo-1',
        ticketPriceCents: 200,
        ticketsRequired: 100,
        ticketsSold: 25,
        state: 'OPEN',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      RafflePool(
        poolId: 'pool-2',
        prizeId: 'demo-2',
        ticketPriceCents: 500,
        ticketsRequired: 200,
        ticketsSold: 120,
        state: 'OPEN',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  Future<RafflePool> getPool(String id) async {
    final res = await dio.get('pools/$id');
    return RafflePool.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LikeStatus> getPoolLikeStatus(String id) async {
    final res = await dio.get('pools/$id/likes');
    return LikeStatus.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LikeStatus> likePool(String id) async {
    final res = await dio.post('pools/$id/like');
    return LikeStatus.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LikeStatus> unlikePool(String id) async {
    final res = await dio.delete('pools/$id/like');
    return LikeStatus.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<RafflePool>> getMyPools() async {
    // Backend route: GET /api/v1/pools/my (requires Authorization header)
    final res = await dio.get('pools/my');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic> ? (raw['data'] as List?) : null) ??
            <dynamic>[];
    return list
        .map((e) => RafflePool.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RafflePool> createPool(RafflePool pool) async {
    final payload = {
      'prize_id': pool.prizeId,
      'ticket_price_cents': pool.ticketPriceCents,
      'tickets_required': pool.ticketsRequired,
    };
    final res = await dio.post('pools/', data: payload);
    return RafflePool.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updatePool(String id, RafflePool pool) async {
    final payload = {
      'prize_id': pool.prizeId,
      'ticket_price_cents': pool.ticketPriceCents,
      'tickets_required': pool.ticketsRequired,
    };
    await dio.put('pools/$id', data: payload);
  }

  Future<void> deletePool(String id) async {
    await dio.delete('pools/$id');
  }
}
