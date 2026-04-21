class GiftItem {
  const GiftItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.priceScore,
    required this.popularityPoints,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String kind;
  final String title;
  final int priceScore;
  final int popularityPoints;
  final int sortOrder;
  final bool isActive;

  factory GiftItem.fromJson(Map<String, dynamic> json) {
    return GiftItem(
      id: json['id'] as String,
      kind: json['kind'] as String? ?? '',
      title: json['title'] as String? ?? '',
      priceScore: (json['price_score'] as num?)?.toInt() ?? 0,
      popularityPoints: (json['popularity_points'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind,
      'title': title,
      'price_score': priceScore,
      'popularity_points': popularityPoints,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  static String emojiForKind(String kind) {
    return switch (kind) {
      'flower' => '🌸',
      'rabbit' => '🐰',
      'cat' => '🐱',
      _ => '🎁',
    };
  }
}
