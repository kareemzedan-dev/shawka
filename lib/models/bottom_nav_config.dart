/// إعدادات شريط التنقل السفلي القابلة للإدارة من لوحة التحكم.
class BottomNavTabConfig {
  const BottomNavTabConfig({
    required this.id,
    this.visible = true,
    this.sortOrder = 0,
    this.showBadge = false,
  });

  /// home | favorites | cart | orders | profile
  final String id;
  final bool visible;
  final int sortOrder;

  /// عادة لتبويب السلة فقط.
  final bool showBadge;

  factory BottomNavTabConfig.fromMap(Map<String, dynamic> map) {
    return BottomNavTabConfig(
      id: (map['id'] as String? ?? '').trim(),
      visible: map['visible'] as bool? ?? true,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      showBadge: map['showBadge'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'visible': visible,
    'sortOrder': sortOrder,
    'showBadge': showBadge,
  };

  BottomNavTabConfig copyWith({
    String? id,
    bool? visible,
    int? sortOrder,
    bool? showBadge,
  }) {
    return BottomNavTabConfig(
      id: id ?? this.id,
      visible: visible ?? this.visible,
      sortOrder: sortOrder ?? this.sortOrder,
      showBadge: showBadge ?? this.showBadge,
    );
  }
}

class BottomNavConfig {
  const BottomNavConfig({
    this.tabs = defaults,
    this.badgeEnabled = true,
    this.badgeStyle = 'count',
  });

  final List<BottomNavTabConfig> tabs;
  final bool badgeEnabled;

  /// count | dot
  final String badgeStyle;

  static const coreTabIds = {'home', 'cart', 'orders', 'profile'};

  static const defaults = [
    BottomNavTabConfig(id: 'home', sortOrder: 0),
    BottomNavTabConfig(id: 'favorites', sortOrder: 1),
    BottomNavTabConfig(id: 'cart', sortOrder: 2, showBadge: true),
    BottomNavTabConfig(id: 'orders', sortOrder: 3),
    BottomNavTabConfig(id: 'profile', sortOrder: 4),
  ];

  factory BottomNavConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const BottomNavConfig();
    final parsed = (map['tabs'] as List?)
        ?.whereType<Map>()
        .map((entry) => BottomNavTabConfig.fromMap(Map<String, dynamic>.from(entry)))
        .where((tab) => tab.id.isNotEmpty)
        .map((tab) => tab.id == 'search' ? tab.copyWith(id: 'favorites') : tab)
        .toList();
    final byId = <String, BottomNavTabConfig>{
      for (final tab in parsed ?? const <BottomNavTabConfig>[]) tab.id: tab,
    };
    final merged = defaults.map((fallback) {
      final override = byId[fallback.id];
      if (override == null) return fallback;
      final visible = coreTabIds.contains(fallback.id) ? true : override.visible;
      return fallback.copyWith(
        visible: visible,
        sortOrder: override.sortOrder,
        showBadge: override.showBadge,
      );
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final style = (map['badgeStyle'] as String? ?? 'count').trim().toLowerCase();
    return BottomNavConfig(
      tabs: merged,
      badgeEnabled: map['badgeEnabled'] as bool? ?? true,
      badgeStyle: style == 'dot' ? 'dot' : 'count',
    );
  }

  Map<String, dynamic> toMap() => {
    'badgeEnabled': badgeEnabled,
    'badgeStyle': badgeStyle,
    'tabs': tabs.map((tab) => tab.toMap()).toList(),
  };

  List<BottomNavTabConfig> get visibleTabs =>
      tabs.where((tab) => tab.visible).toList(growable: false);

  BottomNavConfig copyWith({
    List<BottomNavTabConfig>? tabs,
    bool? badgeEnabled,
    String? badgeStyle,
  }) {
    return BottomNavConfig(
      tabs: tabs ?? this.tabs,
      badgeEnabled: badgeEnabled ?? this.badgeEnabled,
      badgeStyle: badgeStyle ?? this.badgeStyle,
    );
  }
}
