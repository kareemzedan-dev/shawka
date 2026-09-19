import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/theme/admin_theme.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/governorate_repository.dart';

class AdminGovernorateBar extends StatelessWidget {
  const AdminGovernorateBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Governorate selected;
  final ValueChanged<Governorate> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminTheme.surface,
      elevation: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AdminTheme.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.accentMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primaryDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'المحافظة:',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<List<Governorate>>(
                  stream: GovernorateRepository().watchAvailable(),
                  builder: (context, snap) {
                    final raw = snap.data ?? EgyptGovernorates.available;
                    final list = _uniqueById(raw);
                    if (list.isEmpty) {
                      return Text(
                        'لا توجد محافظات متاحة',
                        style:
                            GoogleFonts.cairo(color: AppColors.textSecondary),
                      );
                    }

                    final current = list.firstWhere(
                      (g) => g.id == selected.id,
                      orElse: () => list.first,
                    );

                    if (current.id != selected.id) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        onChanged(current);
                      });
                    }

                    return DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: current.id,
                        isExpanded: true,
                        borderRadius:
                            BorderRadius.circular(AdminTheme.radiusSm),
                        items: list
                            .map(
                              (g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(g.name, style: GoogleFonts.cairo()),
                              ),
                            )
                            .toList(),
                        onChanged: (id) {
                          if (id == null) return;
                          final picked = list.firstWhere((g) => g.id == id);
                          onChanged(picked);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'كل الإدارة لهذه المحافظة فقط',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<Governorate> _uniqueById(List<Governorate> input) {
    final seen = <String>{};
    final out = <Governorate>[];
    for (final g in input) {
      if (seen.add(g.id)) out.add(g);
    }
    return out;
  }
}
