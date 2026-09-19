import 'package:flutter/material.dart';
import 'package:matlobgo/shared/home/home_page_grid_config.dart';
import 'package:matlobgo/web/home/home_page_breakpoints.dart';
import 'package:matlobgo/web/home/home_page_desktop.dart';
import 'package:matlobgo/web/home/home_page_mobile.dart';
import 'package:matlobgo/web/home/home_page_tablet.dart';

/// Picks mobile / tablet / desktop shell while preserving app visual DNA.
class HomePageLayout extends StatelessWidget {
  const HomePageLayout({super.key, required this.builder});

  final Widget Function(BuildContext context, HomePageGridConfig grid) builder;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final kind = HomePageBreakpoints.layoutFor(width);
    final grid = HomePageBreakpoints.gridFor(width);
    final content = builder(context, grid);

    return switch (kind) {
      HomePageLayoutKind.mobile => HomePageMobile(child: content),
      HomePageLayoutKind.tablet => HomePageTablet(child: content),
      HomePageLayoutKind.desktop => HomePageDesktop(child: content),
    };
  }
}
