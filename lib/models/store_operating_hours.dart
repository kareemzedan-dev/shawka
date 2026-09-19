/// جدول ساعات عمل أسبوعي — يُخزَّن في Firestore تحت operatingHours.
class DaySchedule {
  const DaySchedule({
    this.isClosed = false,
    this.openTime = '09:00',
    this.closeTime = '23:00',
  });

  final bool isClosed;
  final String openTime;
  final String closeTime;

  factory DaySchedule.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DaySchedule();
    return DaySchedule(
      isClosed: map['closed'] as bool? ?? false,
      openTime: map['open'] as String? ?? '09:00',
      closeTime: map['close'] as String? ?? '23:00',
    );
  }

  Map<String, dynamic> toMap() => {
        'closed': isClosed,
        'open': openTime,
        'close': closeTime,
      };

  DaySchedule copyWith({
    bool? isClosed,
    String? openTime,
    String? closeTime,
  }) {
    return DaySchedule(
      isClosed: isClosed ?? this.isClosed,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}

class StoreOperatingHours {
  const StoreOperatingHours({required this.days});

  /// مفتاح اليوم: 1=الإثنين … 7=الأحد (DateTime.weekday).
  final Map<int, DaySchedule> days;

  /// التوقيت الشتوي لمصر (UTC+2). الصيفي يُحسَب ديناميكياً.
  static const cairoStandardOffset = Duration(hours: 2);
  static const cairoDstOffset = Duration(hours: 3);

  static const dayLabels = {
    1: 'الإثنين',
    2: 'الثلاثاء',
    3: 'الأربعاء',
    4: 'الخميس',
    5: 'الجمعة',
    6: 'السبت',
    7: 'الأحد',
  };

  /// يوجد جدول محفوظ في Firestore (حتى لو كل الأيام مغلقة).
  bool get hasSchedule => days.isNotEmpty;

  /// إزاحة Africa/Cairo للحظة UTC معيّنة (شتوي/صيفي).
  ///
  /// قواعد مصر منذ 2023:
  /// - بداية الصيفي: آخر جمعة من أبريل الساعة 00:00 (بتوقيت شتوي).
  /// - نهاية الصيفي: آخر خميس من أكتوبر الساعة 00:00 (بتوقيت صيفي).
  static Duration cairoOffsetAtUtc(DateTime utcMoment) {
    final utc = utcMoment.toUtc();
    // نجرّب سنة UTC والسنوات المجاورة قرب حدود السنة.
    for (final year in [utc.year - 1, utc.year, utc.year + 1]) {
      final dstStartUtc = _egyptDstStartUtc(year);
      final dstEndUtc = _egyptDstEndUtc(year);
      if (!utc.isBefore(dstStartUtc) && utc.isBefore(dstEndUtc)) {
        return cairoDstOffset;
      }
    }
    return cairoStandardOffset;
  }

  static DateTime _egyptDstStartUtc(int year) {
    // منتصف الليل بتوقيت شتوي (UTC+2) في آخر جمعة من أبريل.
    final localMidnight = DateTime(year, 4, _lastWeekdayOfMonth(year, 4, DateTime.friday));
    return DateTime.utc(
      localMidnight.year,
      localMidnight.month,
      localMidnight.day,
    ).subtract(cairoStandardOffset);
  }

  static DateTime _egyptDstEndUtc(int year) {
    // منتصف الليل بتوقيت صيفي (UTC+3) في آخر خميس من أكتوبر.
    final localMidnight = DateTime(year, 10, _lastWeekdayOfMonth(year, 10, DateTime.thursday));
    return DateTime.utc(
      localMidnight.year,
      localMidnight.month,
      localMidnight.day,
    ).subtract(cairoDstOffset);
  }

  static int _lastWeekdayOfMonth(int year, int month, int weekday) {
    final lastDay = DateTime(year, month + 1, 0).day;
    var day = lastDay;
    while (DateTime(year, month, day).weekday != weekday) {
      day--;
    }
    return day;
  }

  /// الوقت الحالي بتوقيت القاهرة (ساعة/يوم تقويم محلي للقاهرة).
  static DateTime nowInCairo([DateTime? now]) {
    final utc = (now ?? DateTime.now()).toUtc();
    final cairo = utc.add(cairoOffsetAtUtc(utc));
    return DateTime(
      cairo.year,
      cairo.month,
      cairo.day,
      cairo.hour,
      cairo.minute,
      cairo.second,
      cairo.millisecond,
    );
  }

  factory StoreOperatingHours.empty() => const StoreOperatingHours(days: {});

  factory StoreOperatingHours.defaultSchedule() {
    const day = DaySchedule(openTime: '10:00', closeTime: '23:00');
    return StoreOperatingHours(
      days: {for (var i = 1; i <= 7; i++) i: day},
    );
  }

  factory StoreOperatingHours.fromFirestore(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return StoreOperatingHours.empty();
    final parsed = <int, DaySchedule>{};
    for (final entry in raw.entries) {
      final key = int.tryParse(entry.key);
      if (key == null || key < 1 || key > 7) continue;
      final value = entry.value;
      parsed[key] = DaySchedule.fromMap(
        value is Map ? Map<String, dynamic>.from(value) : null,
      );
    }
    return StoreOperatingHours(days: parsed);
  }

  Map<String, dynamic> toFirestore() {
    return {for (final e in days.entries) '${e.key}': e.value.toMap()};
  }

  DaySchedule day(int weekday) =>
      days[weekday] ?? const DaySchedule(isClosed: true);

  bool isOpenAt(DateTime moment) {
    final now = moment.hour * 60 + moment.minute;

    // نافذة اليوم الحالي.
    final today = days[moment.weekday];
    if (today != null && !today.isClosed) {
      final open = _parseMinutes(today.openTime);
      final close = _parseMinutes(today.closeTime);
      if (open != null && close != null) {
        if (close <= open) {
          // عبور منتصف الليل يبدأ اليوم (مثلاً 22:00 → 02:00)
          if (now >= open) return true;
        } else if (now >= open && now < close) {
          return true;
        }
      }
    }

    // امتداد نافذة الأمس بعد منتصف الليل.
    final yesterdayWeekday = moment.weekday == DateTime.monday
        ? DateTime.sunday
        : moment.weekday - 1;
    final yesterday = days[yesterdayWeekday];
    if (yesterday != null && !yesterday.isClosed) {
      final open = _parseMinutes(yesterday.openTime);
      final close = _parseMinutes(yesterday.closeTime);
      if (open != null && close != null && close <= open && now < close) {
        return true;
      }
    }

    return false;
  }

  /// يقيّم الفتح بتوقيت القاهرة.
  bool isOpenNowInCairo([DateTime? now]) => isOpenAt(nowInCairo(now));

  static int? _parseMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  StoreOperatingHours copyWith({Map<int, DaySchedule>? days}) {
    return StoreOperatingHours(days: days ?? this.days);
  }
}
