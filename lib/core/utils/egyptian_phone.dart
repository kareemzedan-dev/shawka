/// تطبيع والتحقق من أرقام الموبايل المصرية لصيغة E.164 (+20…).
abstract final class EgyptianPhone {
  /// يحوّل إدخال المستخدم إلى `+20XXXXXXXXXX` أو `null` إن كان غير صالح.
  static String? toE164(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '').trim();
    if (digits.isEmpty) return null;

    String national;
    if (digits.startsWith('+20')) {
      national = digits.substring(3);
    } else if (digits.startsWith('0020')) {
      national = digits.substring(4);
    } else if (digits.startsWith('20') && digits.length >= 12) {
      national = digits.substring(2);
    } else if (digits.startsWith('0')) {
      national = digits.substring(1);
    } else {
      national = digits;
    }

    // موبايل مصري: 10 أرقام تبدأ بـ 1
    if (!RegExp(r'^1\d{9}$').hasMatch(national)) return null;
    return '+20$national';
  }

  static bool isValid(String raw) => toE164(raw) != null;

  /// عرض لطيف: `01xxxxxxxxx`
  static String toLocalDisplay(String e164OrRaw) {
    final e164 = toE164(e164OrRaw) ?? e164OrRaw;
    if (e164.startsWith('+20') && e164.length == 13) {
      return '0${e164.substring(3)}';
    }
    return e164OrRaw;
  }

  /// بريد داخلي لتسجيل الدخول بالرقم + كلمة المرور (Firebase Email/Password).
  static String? toAuthEmail(String e164OrRaw) {
    final e164 = toE164(e164OrRaw);
    if (e164 == null) return null;
    final digits = e164.replaceAll(RegExp(r'\D'), '');
    return '$digits@phone.shawka.app';
  }
}
