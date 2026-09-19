import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/ui_polish_tokens.dart';

class PolishSkeleton extends StatefulWidget {
  const PolishSkeleton({
    super.key,
    this.height = 88,
    this.radius = UiPolishTokens.radiusMd,
  });

  final double height;
  final double radius;

  @override
  State<PolishSkeleton> createState() => _PolishSkeletonState();
}

class _PolishSkeletonState extends State<PolishSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = 0.45 + (_pulse.value * 0.25);
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE8ECF3).withValues(alpha: t),
                const Color(0xFFF3F5FA).withValues(alpha: t + 0.1),
                const Color(0xFFE8ECF3).withValues(alpha: t),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PolishListSkeleton extends StatelessWidget {
  const PolishListSkeleton({super.key, this.count = 5, this.itemHeight = 88});

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(UiPolishTokens.spaceMd),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: UiPolishTokens.spaceSm),
      itemBuilder: (_, _) => PolishSkeleton(height: itemHeight),
    );
  }
}
