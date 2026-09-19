import 'package:matlobgo/shared/home/home_page_grid_config.dart';

enum HomePageLayoutKind { mobile, tablet, desktop }

abstract final class HomePageBreakpoints {
  static const double tabletMin = 600;
  static const double desktopMin = 1024;

  static HomePageLayoutKind layoutFor(double width) {
    if (width < tabletMin) return HomePageLayoutKind.mobile;
    if (width < desktopMin) return HomePageLayoutKind.tablet;
    return HomePageLayoutKind.desktop;
  }

  static HomePageGridConfig gridFor(double width) {
    return switch (layoutFor(width)) {
      HomePageLayoutKind.mobile => HomePageGridConfig.mobile,
      HomePageLayoutKind.tablet => HomePageGridConfig.tablet,
      HomePageLayoutKind.desktop => HomePageGridConfig.desktop,
    };
  }
}
