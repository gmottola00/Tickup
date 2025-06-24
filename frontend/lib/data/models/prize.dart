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
        prizeId: json['prize_id'],
        title: json['title'],
        description: json['description'],
        valueCents: json['value_cents'],
        imageUrl: json['image_url'],
        sponsor: json['sponsor'],
        stock: json['stock'],
        createdAt: DateTime.tryParse(json['created_at'] ?? ''),
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
