import 'package:flutter/material.dart';
import 'package:matlobgo/shared/home/home_page_grid_config.dart';

/// Tablet web home — same sections/spacing; 3-column store grid.
class HomePageTablet extends StatelessWidget {
  const HomePageTablet({super.key, required this.child});

  final Widget child;

  static HomePageGridConfig get gridConfig => HomePageGridConfig.tablet;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
