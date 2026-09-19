/// سياسات TTL للتخزين المؤقت — L1 ذاكرة + L2 قرص.
abstract final class CachePolicy {
  static const catalog = CachePolicyConfig(
    memoryTtl: Duration(minutes: 5),
    diskTtl: Duration(minutes: 30),
  );

  static const appSettings = CachePolicyConfig(
    memoryTtl: Duration(minutes: 2),
    diskTtl: Duration(hours: 6),
  );

  static const governorates = CachePolicyConfig(
    memoryTtl: Duration(hours: 1),
    diskTtl: Duration(hours: 24),
  );

  static const promoBanners = CachePolicyConfig(
    memoryTtl: Duration(minutes: 5),
    diskTtl: Duration(minutes: 30),
  );
}

class CachePolicyConfig {
  const CachePolicyConfig({
    required this.memoryTtl,
    required this.diskTtl,
  });

  final Duration memoryTtl;
  final Duration diskTtl;
}
