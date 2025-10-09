import 'package:dio/dio.dart';
import 'package:tickup/core/network/dio_client.dart';
import 'package:tickup/data/models/prize_image.dart';

class PrizeImageRemoteDataSource {
  final Dio dio = DioClient().dio;

  Future<List<PrizeImage>> list(String prizeId) async {
    final res = await dio.get('prizes/$prizeId/images');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic> ? (raw['data'] as List?) : null) ??
            <dynamic>[];
    return list
        .map((e) => PrizeImage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PrizeImage> create(String prizeId, PrizeImageCreate dto) async {
    final res = await dio.post('prizes/$prizeId/images', data: dto.toJson());
    return PrizeImage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PrizeImage> setCover(String prizeId, String imageId) async {
    final res = await dio.put('prizes/$prizeId/images/$imageId',
        data: {'is_cover': true});
    return PrizeImage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<PrizeImage>> reorder(
    String prizeId,
    List<PrizeImageReorderItem> items,
  ) async {
    final res = await dio.put('prizes/$prizeId/images/reorder',
        data: {'items': items.map((e) => e.toJson()).toList()});
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic> ? (raw['data'] as List?) : null) ??
            <dynamic>[];
    return list
        .map((e) => PrizeImage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> delete(String prizeId, String imageId) async {
    await dio.delete('prizes/$prizeId/images/$imageId');
  }
}

