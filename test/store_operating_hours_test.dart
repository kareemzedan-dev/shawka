import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/models/store_operating_hours.dart';

void main() {
  group('StoreOperatingHours Cairo offset', () {
    test('uses UTC+3 during Egypt summer DST (August)', () {
      final utc = DateTime.utc(2026, 8, 13, 21, 10); // 00:10 Cairo DST
      expect(
        StoreOperatingHours.cairoOffsetAtUtc(utc),
        StoreOperatingHours.cairoDstOffset,
      );
      final cairo = StoreOperatingHours.nowInCairo(utc);
      expect(cairo.weekday, DateTime.friday);
      expect(cairo.hour, 0);
      expect(cairo.minute, 10);
    });

    test('uses UTC+2 during Egypt winter (January)', () {
      final utc = DateTime.utc(2026, 1, 15, 10, 0);
      expect(
        StoreOperatingHours.cairoOffsetAtUtc(utc),
        StoreOperatingHours.cairoStandardOffset,
      );
      final cairo = StoreOperatingHours.nowInCairo(utc);
      expect(cairo.hour, 12);
    });
  });

  group('isOpenAt', () {
    test('respects same-day window', () {
      final hours = StoreOperatingHours(
        days: {
          DateTime.friday: const DaySchedule(
            openTime: '10:00',
            closeTime: '23:00',
          ),
        },
      );
      expect(
        hours.isOpenAt(DateTime(2026, 8, 14, 12, 0)),
        isTrue,
      );
      expect(
        hours.isOpenAt(DateTime(2026, 8, 14, 0, 10)),
        isFalse,
      );
    });

    test('supports overnight window across midnight', () {
      final hours = StoreOperatingHours(
        days: {
          DateTime.thursday: const DaySchedule(
            openTime: '22:00',
            closeTime: '02:00',
          ),
        },
      );
      expect(hours.isOpenAt(DateTime(2026, 8, 13, 23, 30)), isTrue);
      // بعد منتصف الليل = يوم الجمعة، لكنه امتداد دوام الخميس.
      expect(hours.isOpenAt(DateTime(2026, 8, 14, 1, 30)), isTrue);
      expect(hours.isOpenAt(DateTime(2026, 8, 13, 12, 0)), isFalse);
    });

    test('friday all-day open is detected at midnight Cairo DST', () {
      final hours = StoreOperatingHours(
        days: {
          for (var i = 1; i <= 7; i++)
            i: const DaySchedule(openTime: '00:00', closeTime: '23:59'),
        },
      );
      final utc = DateTime.utc(2026, 8, 13, 21, 10); // Fri 00:10 Cairo
      expect(hours.isOpenNowInCairo(utc), isTrue);
    });
  });
}
