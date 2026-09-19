import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

/// Shown when a catalog network image fails after all URL candidates.
class CatalogImagePlaceholder extends StatelessWidget {
  const CatalogImagePlaceholder({
    super.key,
    this.icon = Icons.image_not_supported_outlined,
    this.label,
    this.onRetry,
    this.compact = false,
  });

  final IconData icon;
  final String? label;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navyLight.withValues(alpha: 0.92),
            AppColors.navy.withValues(alpha: 0.78),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 22 : 30,
            color: AppColors.white.withValues(alpha: 0.42),
          ),
          if (label != null && !compact) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.white.withValues(alpha: 0.55),
                  height: 1.2,
                ),
              ),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white.withValues(alpha: 0.85),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('إعادة المحاولة', style: TextStyle(fontSize: 11)),
            ),
          ],
        ],
      ),
    );
  }
}
