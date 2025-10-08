class LikeStatus {
  final int likes;
  final bool likedByMe;

  const LikeStatus({required this.likes, required this.likedByMe});

  factory LikeStatus.fromJson(Map<String, dynamic> json) => LikeStatus(
        likes: (json['likes'] ?? 0) is int
            ? json['likes'] as int
            : int.tryParse((json['likes'] ?? '0').toString()) ?? 0,
        likedByMe: (json['liked_by_me'] ?? false) == true,
      );
}

