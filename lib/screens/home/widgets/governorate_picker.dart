import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/app_config_service.dart';

Future<Governorate?> showGovernoratePicker(
  BuildContext context, {
  required Governorate current,
}) {
  return showModalBottomSheet<Governorate>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _GovernorateSheet(current: current),
  );
}

class _GovernorateSheet extends StatelessWidget {
  const _GovernorateSheet({required this.current});

  final Governorate current;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.82;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + media.padding.bottom),
            child: StreamBuilder<List<Governorate>>(
              stream: AppConfigService.instance.watchGovernorates(),
              builder: (context, snapshot) {
                final list = snapshot.data ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'اختر المحافظة',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppBranding.shortName} متاح في محافظات محددة',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        list.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: list.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final gov = list[index];
                            final isSelected = gov.id == current.id;
                            return Material(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: gov.isAvailable
                                    ? () => Navigator.pop(context, gov)
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        color: gov.isAvailable
                                            ? (isSelected
                                                ? AppColors.primary
                                                : AppColors.textSecondary)
                                            : AppColors.textHint,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              gov.name,
                                              style: GoogleFonts.cairo(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: gov.isAvailable
                                                    ? AppColors.textPrimary
                                                    : AppColors.textHint,
                                              ),
                                            ),
                                            if (!gov.isAvailable)
                                              Text(
                                                'قريباً',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
