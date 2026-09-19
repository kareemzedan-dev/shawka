import 'package:flutter/material.dart';
import 'package:matlobgo/web/services/web_cart_service.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/services/tarfa_cart_drawer_controller.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_web_image.dart';
import 'package:matlobgo/web/widgets/web_app_conversion_modal.dart';

class TarfaCartDrawer extends StatelessWidget {
  const TarfaCartDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TarfaCartDrawerController.instance,
      builder: (context, _) {
        final open = TarfaCartDrawerController.instance.isOpen;
        return Stack(
          children: [
            AnimatedOpacity(
              opacity: open ? 1 : 0,
              duration: TarfaTokens.animNormal,
              child: IgnorePointer(
                ignoring: !open,
                child: GestureDetector(
                  onTap: TarfaCartDrawerController.instance.close,
                  child: Container(color: Colors.black.withValues(alpha: 0.4)),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: TarfaTokens.animNormal,
              curve: TarfaTokens.curve,
              top: 0,
              bottom: 0,
              left: open ? 0 : -420,
              width: 420,
              child: Material(
                elevation: 24,
                color: TarfaTokens.surface,
                child: const _CartDrawerContent(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class TarfaMobileCartDrawer extends StatelessWidget {
  const TarfaMobileCartDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TarfaCartDrawerController.instance,
      builder: (context, _) {
        final open = TarfaCartDrawerController.instance.isOpen;
        if (!open) return const SizedBox.shrink();

        return Stack(
          children: [
            GestureDetector(
              onTap: TarfaCartDrawerController.instance.close,
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Material(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(TarfaTokens.radiusLg),
                  ),
                  clipBehavior: Clip.antiAlias,
                  color: TarfaTokens.surface,
                  child: _CartDrawerContent(scrollController: scrollController),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _CartDrawerContent extends StatefulWidget {
  const _CartDrawerContent({this.scrollController});

  final ScrollController? scrollController;

  @override
  State<_CartDrawerContent> createState() => _CartDrawerContentState();
}

class _CartDrawerContentState extends State<_CartDrawerContent> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WebCartService.instance,
      builder: (context, _) {
        final cart = WebCartService.instance;
        final isMobile =
            MediaQuery.sizeOf(context).width < TarfaTokens.mobileBreakpoint;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(TarfaTokens.s24),
              child: Row(
                children: [
                  Text('سلة الطلبات', style: TarfaTokens.headlineMedium(context)),
                  const Spacer(),
                  IconButton(
                    onPressed: TarfaCartDrawerController.instance.close,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: cart.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: TarfaTokens.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: TarfaTokens.s16),
                          Text(
                            'سلتك فارغة',
                            style: TarfaTokens.titleLarge(context),
                          ),
                          const SizedBox(height: TarfaTokens.s8),
                          Text(
                            'أضف منتجات من المتاجر القريبة',
                            style: TarfaTokens.bodyMedium(context),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: TarfaTokens.s24,
                      ),
                      itemCount: cart.items.length,
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: TarfaTokens.s16),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: TarfaWebImage(
                                  kind: TarfaImageKind.product,
                                  width: 64,
                                  height: 64,
                                  imageUrl: item.imageUrl,
                                  thumbnailUrl: item.imageThumbUrl,
                                ),
                              ),
                              const SizedBox(width: TarfaTokens.s12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: TarfaTokens.titleMedium(context),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      item.storeName,
                                      style: TarfaTokens.bodyMedium(context),
                                    ),
                                    Text(
                                      '${item.price.toStringAsFixed(0)} ج.م',
                                      style: TarfaTokens.labelLarge(context).copyWith(
                                        color: TarfaTokens.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _QuantityControl(
                                quantity: item.quantity,
                                onDecrease: () => cart.updateQuantity(
                                  item.id,
                                  item.quantity - 1,
                                ),
                                onIncrease: () => cart.updateQuantity(
                                  item.id,
                                  item.quantity + 1,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (!cart.isEmpty)
              Container(
                padding: EdgeInsets.fromLTRB(
                  TarfaTokens.s24,
                  TarfaTokens.s16,
                  TarfaTokens.s24,
                  isMobile ? TarfaTokens.s32 : TarfaTokens.s24,
                ),
                decoration: BoxDecoration(
                  color: TarfaTokens.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(TarfaTokens.radiusLg),
                  ),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _couponController,
                      decoration: InputDecoration(
                        hintText: 'كود الخصم',
                        hintStyle: TarfaTokens.bodyMedium(context),
                        suffixIcon: TextButton(
                          onPressed: () {},
                          child: const Text('تطبيق'),
                        ),
                      ),
                    ),
                    const SizedBox(height: TarfaTokens.s16),
                    _SummaryRow(
                      label: 'المجموع الفرعي',
                      value: '${cart.subtotal.toStringAsFixed(0)} ج.م',
                    ),
                    const SizedBox(height: TarfaTokens.s8),
                    _SummaryRow(
                      label: 'رسوم التوصيل',
                      value: '${cart.deliveryFee.toStringAsFixed(0)} ج.م',
                    ),
                    const Divider(height: TarfaTokens.s24),
                    _SummaryRow(
                      label: 'الإجمالي',
                      value: '${cart.total.toStringAsFixed(0)} ج.م',
                      bold: true,
                    ),
                    const SizedBox(height: TarfaTokens.s16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          TarfaCartDrawerController.instance.close();
                          showWebAppConversionModal(context);
                        },
                        child: const Text('إتمام الطلب'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TarfaTokens.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_rounded, size: 18),
            visualDensity: VisualDensity.compact,
          ),
          Text('$quantity', style: TarfaTokens.labelLarge(context)),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_rounded, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? TarfaTokens.titleLarge(context)
        : TarfaTokens.bodyLarge(context);

    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}
