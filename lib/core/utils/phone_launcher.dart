import 'package:url_launcher/url_launcher.dart';

Future<bool> launchPhoneCall(String phone) async {
  final normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (normalized.isEmpty) return false;

  final uri = Uri(scheme: 'tel', path: normalized);
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri);
}
