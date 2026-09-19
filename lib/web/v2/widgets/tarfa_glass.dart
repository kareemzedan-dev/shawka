import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';

class TarfaGlass extends StatelessWidget {
  const TarfaGlass({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur = 12,
    this.opacity = 0.72,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? TarfaTokens.borderRadius;
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: TarfaTokens.surface.withValues(alpha: opacity),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: TarfaTokens.shadowSm,
          ),
          child: child,
        ),
      ),
    );
  }
}
