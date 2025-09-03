import 'package:dio/dio.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/core/network/dio_client.dart';
import 'package:tickup/core/config/env_config.dart';

class PrizeRemoteDataSource {
  final Dio dio = DioClient().dio;

  Future<List<Prize>> getPrizes() async {
    // if (EnvConfig.isDevelopment) {
    //   return _mockPrizes();
    // }
    // Backend route: GET /api/v1/prizes/all_prizes
    final res = await dio.get('/prizes/all_prizes');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic> ? (raw['data'] as List?) : null) ??
            <dynamic>[];
    return list.map((e) => Prize.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Prize>> _mockPrizes() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return [
      Prize(
        prizeId: 'demo-1',
        title: 'Gift Card 50€',
        description: 'Buono acquisto digitale da 50€ utilizzabile online.',
        valueCents: 5000,
        imageUrl: 'https://picsum.photos/seed/prize1/600/400',
        sponsor: 'Acme Inc.',
        stock: 25,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Prize(
        prizeId: 'demo-2',
        title: 'Cuffie Wireless',
        description: 'Audio HD con cancellazione del rumore attiva.',
        valueCents: 8999,
        imageUrl: 'https://picsum.photos/seed/prize2/600/400',
        sponsor: 'Soundify',
        stock: 12,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Prize(
        prizeId: 'demo-3',
        title: 'Action Cam 4K',
        description: 'Stabilizzazione e waterproof fino a 10m.',
        valueCents: 12999,
        imageUrl: 'https://picsum.photos/seed/prize3/600/400',
        sponsor: 'GoMotion',
        stock: 5,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      Prize(
        prizeId: 'demo-4',
        title: 'Abbonamento Premium 3 mesi',
        description: 'Accesso illimitato a contenuti esclusivi per 3 mesi.',
        valueCents: 2999,
        imageUrl: 'https://picsum.photos/seed/prize4/600/400',
        sponsor: 'StreamPlus',
        stock: 100,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
  }

  Future<Prize> getPrize(String id) async {
    final res = await dio.get('/prizes/$id');
    return Prize.fromJson(res.data);
  }

  Future<Prize> createPrize(Prize prize) async {
    final res = await dio.post('/prizes/', data: prize.toJson());
    return Prize.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updatePrize(String id, Prize prize) async {
    await dio.put('/prizes/$id', data: prize.toJson());
  }

  Future<void> deletePrize(String id) async {
    await dio.delete('/prizes/$id');
  }
}
