import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/web/services/web_analytics_service.dart';
import 'package:matlobgo/web/services/web_cart_service.dart';
import 'package:matlobgo/web/services/web_conversion_service.dart';
import 'package:matlobgo/web/services/web_seo_service.dart';
import 'package:matlobgo/web/widgets/web_app_conversion_modal.dart';
import 'package:matlobgo/core/constants/app_branding.dart';

class WebCartScreen extends StatefulWidget {
  const WebCartScreen({super.key});

  @override
  State<WebCartScreen> createState() => _WebCartScreenState();
}

class _WebCartScreenState extends State<WebCartScreen> {
  @override
  void initState() {
    super.initState();
    WebSeoService.instance.apply(
      title: 'سلة التسوق',
      description: AppBranding.cartSeoDescription,
      canonicalPath: '/cart',
    );
    WebCartService.instance.addListener(_onCart);
  }

  @override
  void dispose() {
    WebCartService.instance.removeListener(_onCart);
    super.dispose();
  }

  void _onCart() {
    WebConversionService.instance.onCartChanged();
    if (mounted) setState(() {});
  }

  Future<void> _checkout() async {
    final cart = WebCartService.instance;
    await WebAnalyticsService.instance.checkoutGateReached(
      cartTotal: cart.total,
    );
    if (!mounted) return;
    await showWebAppConversionModal(context);
  }

  @override
  Widget build(BuildContext context) {
    final cart = WebCartService.instance;

    return PremiumBackground.body(
      context,
      Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.navy,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: SafeArea(
              bottom: false,
              child: Text(
                'سلة التسوق',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Text(
                      'سلتك فارغة — اكتشف الموردين وأضف منتجات',
                      style: GoogleFonts.cairo(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: HomeTheme.borderMd,
                          boxShadow: HomeTheme.softShadowLight,
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: CatalogNetworkImage(
                                  imageUrl: item.imageUrl,
                                  thumbnailUrl: item.imageThumbUrl,
                                  fallback:
                                      Container(color: AppColors.surfaceMuted),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    item.storeName,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  '${item.lineTotal.toInt()} ج.م',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () => cart.updateQuantity(
                                        item.id,
                                        item.quantity - 1,
                                      ),
                                    ),
                                    Text('${item.quantity}'),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => cart.updateQuantity(
                                        item.id,
                                        item.quantity + 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (!cart.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: HomeTheme.softShadowNav,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    _row('المجموع الفرعي', cart.subtotal),
                    _row('التوصيل (تقديري)', cart.deliveryFee),
                    const Divider(),
                    _row('الإجمالي', cart.total, bold: true),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _checkout,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'إتمام الطلب',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${value.toInt()} ج.م',
            style: GoogleFonts.cairo(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
