/// Grid layout tokens — mobile app uses 2 columns @ 0.82 aspect.
class HomePageGridConfig {
  const HomePageGridConfig({
    required this.crossAxisCount,
    this.childAspectRatio = 0.82,
    this.mainAxisSpacing = 14,
    this.crossAxisSpacing = 14,
  });

  final int crossAxisCount;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  static const mobile = HomePageGridConfig(crossAxisCount: 2);

  static const tablet = HomePageGridConfig(crossAxisCount: 3);

  static const desktop = HomePageGridConfig(crossAxisCount: 4);
}
