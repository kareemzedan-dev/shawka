import 'package:flutter/material.dart';

/// يحدد إن التبويب الحالي ظاهر — لإيقاف المؤقتات والأنيميشن في الخلفية.
class TabActivityScope extends InheritedWidget {
  const TabActivityScope({
    super.key,
    required this.isActive,
    required super.child,
  });

  final bool isActive;

  static bool isActiveOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<TabActivityScope>();
    if (scope != null && !scope.isActive) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    return true;
  }

  @override
  bool updateShouldNotify(TabActivityScope oldWidget) =>
      isActive != oldWidget.isActive;
}
