class Prize {
  final String prizeId;
  final String title;
  final String description;
  final int valueCents;
  final String imageUrl;
  final String sponsor;
  final int stock;
  final DateTime? createdAt;

  Prize({
    required this.prizeId,
    required this.title,
    required this.description,
    required this.valueCents,
    required this.imageUrl,
    required this.sponsor,
    required this.stock,
    this.createdAt,
  });

  factory Prize.fromJson(Map<String, dynamic> json) => Prize(
        prizeId: (json['prize_id'] ?? json['id']).toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        valueCents: (json['value_cents'] ?? 0) is int
            ? json['value_cents'] as int
            : int.tryParse((json['value_cents'] ?? '0').toString()) ?? 0,
        imageUrl: (json['image_url'] ?? '').toString(),
        sponsor: (json['sponsor'] ?? '').toString(),
        stock: (json['stock'] ?? 0) is int
            ? json['stock'] as int
            : int.tryParse((json['stock'] ?? '0').toString()) ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'value_cents': valueCents,
        'image_url': imageUrl,
        'sponsor': sponsor,
        'stock': stock,
      };
}
