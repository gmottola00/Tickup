class CardGridConfig {
  const CardGridConfig({required this.crossAxisCount, required this.childAspectRatio});

  final int crossAxisCount;
  final double childAspectRatio;
}

CardGridConfig defaultCardGridConfig(double width) {
  if (width >= 900) {
    return const CardGridConfig(crossAxisCount: 6, childAspectRatio: 3 / 4);
  }
  if (width >= 600) {
    return const CardGridConfig(crossAxisCount: 3, childAspectRatio: 3 / 4);
  }
  return const CardGridConfig(crossAxisCount: 2, childAspectRatio: 2 / 3);
}
