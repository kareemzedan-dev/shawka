import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

class SafeAssetImage extends StatelessWidget {
  const SafeAssetImage({
    super.key,
    required this.asset,
    this.fit = BoxFit.cover,
    this.fallbackIcon,
    this.fallbackColor,
  });

  final String asset;
  final BoxFit fit;
  final IconData? fallbackIcon;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: fit,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => Container(
        color: fallbackColor ?? AppColors.navyLight,
        alignment: Alignment.center,
        child: Icon(
          fallbackIcon ?? Icons.image_not_supported_outlined,
          color: AppColors.white.withValues(alpha: 0.5),
          size: 32,
        ),
      ),
    );
  }
}
