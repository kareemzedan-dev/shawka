import 'package:flutter/material.dart';
import 'package:matlobgo/shared/home/home_page_grid_config.dart';
import 'package:matlobgo/web/config/web_constants.dart';

/// Desktop web home — same DNA; 4-column grid inside max content width.
class HomePageDesktop extends StatelessWidget {
  const HomePageDesktop({super.key, required this.child});

  final Widget child;

  static HomePageGridConfig get gridConfig => HomePageGridConfig.desktop;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: WebConstants.maxContentWidth),
        child: child,
      ),
    );
  }
}
