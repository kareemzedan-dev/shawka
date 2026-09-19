import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/activity_scope_utils.dart';
import 'package:matlobgo/models/customer_activity_type.dart';
import 'package:matlobgo/repositories/customer_activity_type_repository.dart';

/// اختيار متعدد لأنشطة الظهور — فارغ = كل الأنشطة.
class AdminActivityTypeMultiSelect extends StatelessWidget {
  const AdminActivityTypeMultiSelect({
    super.key,
    required this.selectedIds,
    required this.onChanged,
    this.helperText =
        'اتركه فارغاً ليظهر لكل الأنشطة، أو اختر نشاطاً أو أكثر',
    this.compact = false,
  });

  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;
  final String helperText;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CustomerActivityType>>(
      stream: CustomerActivityTypeRepository().watchActive(),
      builder: (context, snap) {
        final types = snap.data ?? CustomerActivityTypeDefaults.entries;
        if (types.isEmpty) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: 'الأنشطة الظاهرة',
              labelStyle: GoogleFonts.cairo(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              helperText: 'أضف أنشطة من لوحة أنواع النشاط أولاً',
              helperStyle: GoogleFonts.cairo(fontSize: 11),
            ),
            child: Text(
              'لا توجد أنشطة نشطة',
              style: GoogleFonts.cairo(color: AppColors.textSecondary),
            ),
          );
        }

        final names = {for (final t in types) t.id: t.name};
        final summary = ActivityScopeUtils.summaryLabel(
          selectedIds.toList(),
          names,
        );

        return InputDecorator(
          decoration: InputDecoration(
            labelText: 'الأنشطة الظاهرة',
            labelStyle: GoogleFonts.cairo(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            helperText: helperText,
            helperStyle: GoogleFonts.cairo(fontSize: 11),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!compact) ...[
                Text(
                  summary,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selectedIds.isEmpty
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text(
                      'كل الأنشطة',
                      style: GoogleFonts.cairo(fontSize: 12.5),
                    ),
                    selected: selectedIds.isEmpty,
                    onSelected: (_) => onChanged({}),
                  ),
                  for (final t in types)
                    FilterChip(
                      avatar: Icon(t.icon, size: 16),
                      label: Text(
                        t.name,
                        style: GoogleFonts.cairo(fontSize: 12.5),
                      ),
                      selected: selectedIds.contains(t.id),
                      onSelected: (v) {
                        final next = Set<String>.from(selectedIds);
                        if (v) {
                          next.add(t.id);
                        } else {
                          next.remove(t.id);
                        }
                        onChanged(next);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
