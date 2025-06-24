import 'package:dio/dio.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/core/network/dio_client.dart';

class PrizeRemoteDataSource {
  final Dio dio = DioClient().dio;

  Future<Prize> getPrize(String id) async {
    final res = await dio.get('/api/v1/prize/$id');
    return Prize.fromJson(res.data);
  }

  Future<void> createPrize(Prize prize) async {
    await dio.post('/api/v1/prize/', data: prize.toJson());
  }

  Future<void> updatePrize(String id, Prize prize) async {
    await dio.put('/api/v1/prize/$id', data: prize.toJson());
  }

  Future<void> deletePrize(String id) async {
    await dio.delete('/api/v1/prize/$id');
  }
}
