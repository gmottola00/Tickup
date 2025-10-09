class PrizeImage {
  final String imageId;
  final String prizeId;
  final String bucket;
  final String storagePath;
  final String url;
  final bool isCover;
  final int? sortOrder;
  final DateTime createdAt;

  const PrizeImage({
    required this.imageId,
    required this.prizeId,
    required this.bucket,
    required this.storagePath,
    required this.url,
    required this.isCover,
    required this.createdAt,
    this.sortOrder,
  });

  factory PrizeImage.fromJson(Map<String, dynamic> json) => PrizeImage(
        imageId: (json['image_id'] ?? '').toString(),
        prizeId: (json['prize_id'] ?? '').toString(),
        bucket: (json['bucket'] ?? '').toString(),
        storagePath: (json['storage_path'] ?? '').toString(),
        url: (json['url'] ?? '').toString(),
        isCover: (json['is_cover'] ?? false) == true,
        sortOrder: json['sort_order'] is int
            ? json['sort_order'] as int
            : int.tryParse((json['sort_order'] ?? '').toString()),
        createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class PrizeImageCreate {
  final String bucket;
  final String storagePath;
  final String url;
  final bool? isCover;
  final int? sortOrder;

  const PrizeImageCreate({
    required this.bucket,
    required this.storagePath,
    required this.url,
    this.isCover,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() => {
        'bucket': bucket,
        'storage_path': storagePath,
        'url': url,
        if (isCover != null) 'is_cover': isCover,
        if (sortOrder != null) 'sort_order': sortOrder,
      };
}

class PrizeImageReorderItem {
  final String imageId;
  final int sortOrder;

  const PrizeImageReorderItem({required this.imageId, required this.sortOrder});

  Map<String, dynamic> toJson() => {
        'image_id': imageId,
        'sort_order': sortOrder,
      };
}

