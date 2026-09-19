import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/web/services/web_conversion_service.dart';
import 'package:matlobgo/web/widgets/web_app_conversion_modal.dart';

class WebConversionBanner extends StatelessWidget {
  const WebConversionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WebConversionService.instance,
      builder: (context, _) {
        final kind = WebConversionService.instance.bannerKind;
        if (kind == WebConversionBannerKind.none) {
          return const SizedBox.shrink();
        }

        final isDiscount =
            kind == WebConversionBannerKind.firstOrderDiscount;
        final text = isDiscount
            ? 'احصل على خصم أول طلب عند تحميل التطبيق'
            : 'أكمل طلبك عبر التطبيق واحصل على مزايا إضافية';

        return Material(
          elevation: 8,
          color: isDiscount ? AppColors.primary : AppColors.navy,
          child: SafeArea(
            top: false,
            child: InkWell(
              onTap: () => showWebAppConversionModal(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      isDiscount
                          ? Icons.local_offer_rounded
                          : Icons.smartphone_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
