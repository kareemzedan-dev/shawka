import 'package:matlobgo/config/branding/branding.dart';

/// Contact details shown on web — sourced from [Branding.current].
abstract final class TarfaContactInfo {
  static String get email => Branding.current.supportEmail;
  static String get phone => Branding.current.supportPhone;
  static String get phoneTel => Branding.current.supportPhoneTel;
  static String get emailMailto => Branding.current.supportEmailMailto;
  static String get address => Branding.current.address;
}
