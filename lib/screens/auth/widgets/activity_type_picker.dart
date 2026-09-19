import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/customer_activity_type.dart';

class ActivityTypePicker extends StatelessWidget {
  const ActivityTypePicker({
    super.key,
    required this.types,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CustomerActivityType> types;
  final String? selectedId;
  final ValueChanged<CustomerActivityType> onSelected;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'لا توجد أنواع نشاط متاحة حالياً. حاول لاحقاً.',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final type in types)
          _ActivityChip(
            type: type,
            selected: type.id == selectedId,
            onTap: () => onSelected(type),
          ),
      ],
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final CustomerActivityType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type.icon,
                size: 20,
                color: selected ? AppColors.primaryDark : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                type.name,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
