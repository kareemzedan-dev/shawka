import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/store_operating_hours.dart';

class AdminOperatingHoursEditor extends StatelessWidget {
  const AdminOperatingHoursEditor({
    super.key,
    required this.hours,
    required this.onChanged,
  });

  final StoreOperatingHours hours;
  final ValueChanged<StoreOperatingHours> onChanged;

  Future<void> _pickTime(
    BuildContext context, {
    required String initial,
    required ValueChanged<String> onPicked,
  }) async {
    final parts = initial.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 9,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      ),
      helpText: 'اختر الوقت',
    );
    if (picked == null) return;
    onPicked(
      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = hours.days.isEmpty
        ? StoreOperatingHours.defaultSchedule().days
        : hours.days;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'ساعات العمل',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => onChanged(StoreOperatingHours.defaultSchedule()),
                  child: Text('افتراضي', style: GoogleFonts.cairo(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var weekday = 1; weekday <= 7; weekday++) ...[
              _DayRow(
                label: StoreOperatingHours.dayLabels[weekday]!,
                schedule: days[weekday] ?? const DaySchedule(isClosed: true),
                onChanged: (next) {
                  final updated = Map<int, DaySchedule>.from(days)
                    ..[weekday] = next;
                  onChanged(StoreOperatingHours(days: updated));
                },
                onPickTime: (initial, onPicked) => _pickTime(
                  context,
                  initial: initial,
                  onPicked: onPicked,
                ),
              ),
              if (weekday < 7) const Divider(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.label,
    required this.schedule,
    required this.onChanged,
    required this.onPickTime,
  });

  final String label;
  final DaySchedule schedule;
  final ValueChanged<DaySchedule> onChanged;
  final Future<void> Function(String initial, ValueChanged<String> onPicked)
      onPickTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: GoogleFonts.cairo(fontSize: 12)),
        ),
        Switch(
          value: !schedule.isClosed,
          onChanged: (open) => onChanged(schedule.copyWith(isClosed: !open)),
        ),
        if (!schedule.isClosed) ...[
          TextButton(
            onPressed: () => onPickTime(schedule.openTime, (v) {
              onChanged(schedule.copyWith(openTime: v));
            }),
            child: Text(schedule.openTime, style: GoogleFonts.cairo(fontSize: 12)),
          ),
          Text('—', style: GoogleFonts.cairo(color: AppColors.textHint)),
          TextButton(
            onPressed: () => onPickTime(schedule.closeTime, (v) {
              onChanged(schedule.copyWith(closeTime: v));
            }),
            child: Text(schedule.closeTime, style: GoogleFonts.cairo(fontSize: 12)),
          ),
        ] else
          Text(
            'مغلق',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}
