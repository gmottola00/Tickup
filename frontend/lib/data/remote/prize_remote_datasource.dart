import 'package:dio/dio.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/core/network/dio_client.dart';

class PrizeRemoteDataSource {
  final Dio dio = DioClient().dio;

  Future<Prize> getPrize(String id) async {
    final res = await dio.get('/prizes/$id');
    return Prize.fromJson(res.data);
  }

  Future<void> createPrize(Prize prize) async {
    await dio.post('/prizes/', data: prize.toJson());
  }

  Future<void> updatePrize(String id, Prize prize) async {
    await dio.put('/prizes/$id', data: prize.toJson());
  }

  Future<void> deletePrize(String id) async {
    await dio.delete('/prizes/$id');
  }
}
