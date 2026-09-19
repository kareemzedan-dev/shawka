import 'package:flutter/material.dart';
import 'package:matlobgo/shared/home/home_page_grid_config.dart';

/// Mobile web home — pixel-identical grid to the native app (2 columns).
class HomePageMobile extends StatelessWidget {
  const HomePageMobile({super.key, required this.child});

  final Widget child;

  static HomePageGridConfig get gridConfig => HomePageGridConfig.mobile;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
