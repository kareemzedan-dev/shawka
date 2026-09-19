import 'package:flutter/material.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';

class TarfaSkeleton extends StatefulWidget {
  const TarfaSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<TarfaSkeleton> createState() => _TarfaSkeletonState();
}

class _TarfaSkeletonState extends State<TarfaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? TarfaTokens.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF1F5F9),
                Color(0xFFE2E8F0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TarfaStoreCardSkeleton extends StatelessWidget {
  const TarfaStoreCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TarfaTokens.surface,
        borderRadius: TarfaTokens.borderRadius,
        boxShadow: TarfaTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TarfaSkeleton(
            width: double.infinity,
            height: 180,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(TarfaTokens.radius),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(TarfaTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TarfaSkeleton(width: 160, height: 18, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: TarfaTokens.s8),
                TarfaSkeleton(width: 120, height: 14, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: TarfaTokens.s12),
                TarfaSkeleton(width: double.infinity, height: 12, borderRadius: BorderRadius.circular(8)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
