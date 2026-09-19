import 'package:flutter/material.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_web_image.dart';

class TarfaProductCard extends StatefulWidget {
  const TarfaProductCard({
    super.key,
    required this.store,
    required this.product,
    required this.onAdd,
    this.onTap,
  });

  final Store store;
  final Product product;
  final VoidCallback onAdd;
  final VoidCallback? onTap;

  @override
  State<TarfaProductCard> createState() => _TarfaProductCardState();
}

class _TarfaProductCardState extends State<TarfaProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1,
        duration: TarfaTokens.animFast,
        curve: TarfaTokens.curve,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: TarfaTokens.borderRadius,
            child: AnimatedContainer(
              duration: TarfaTokens.animFast,
              decoration: BoxDecoration(
                color: TarfaTokens.surface,
                borderRadius: TarfaTokens.borderRadius,
                boxShadow:
                    _hovered ? TarfaTokens.shadowMd : TarfaTokens.shadowSm,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TarfaWebImage(
                    kind: TarfaImageKind.product,
                    imageUrl: product.imageUrl,
                    thumbnailUrl: product.imageThumbUrl,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(TarfaTokens.s16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TarfaTokens.titleMedium(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (product.description != null &&
                              product.description!.isNotEmpty) ...[
                            const SizedBox(height: TarfaTokens.s4),
                            Text(
                              product.description!,
                              style: TarfaTokens.bodyMedium(context),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const Spacer(),
                          const SizedBox(height: TarfaTokens.s8),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${product.price.toStringAsFixed(0)} ج.م',
                                  style: TarfaTokens.titleLarge(context)
                                      .copyWith(color: TarfaTokens.secondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: TarfaTokens.s8),
                              AnimatedScale(
                                scale: _hovered ? 1.05 : 1,
                                duration: TarfaTokens.animFast,
                                child: FilledButton.icon(
                                  onPressed: widget.onAdd,
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('أضف'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: TarfaTokens.s16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
