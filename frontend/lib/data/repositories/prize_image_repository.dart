import 'package:tickup/data/models/prize_image.dart';
import 'package:tickup/data/remote/prize_image_remote_datasource.dart';

class PrizeImageRepository {
  final PrizeImageRemoteDataSource _remote = PrizeImageRemoteDataSource();

  Future<List<PrizeImage>> list(String prizeId) => _remote.list(prizeId);
  Future<PrizeImage> create(String prizeId, PrizeImageCreate dto) =>
      _remote.create(prizeId, dto);
  Future<PrizeImage> setCover(String prizeId, String imageId) =>
      _remote.setCover(prizeId, imageId);
  Future<List<PrizeImage>> reorder(
          String prizeId, List<PrizeImageReorderItem> items) =>
      _remote.reorder(prizeId, items);
  Future<void> delete(String prizeId, String imageId) =>
      _remote.delete(prizeId, imageId);
}

