import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

/// أيقونات خريطة مخصّصة — متجر / توصيل / موتوسيكل المندوب.
abstract final class TrackingMapMarkers {
  static BitmapDescriptor? _store;
  static BitmapDescriptor? _customer;
  static BitmapDescriptor? _motorcycle;
  static BitmapDescriptor? _motorcycleAlt;

  static Future<void> ensureLoaded() async {
    _store ??= await _paintLabeledPin(
      fill: AppColors.primary,
      icon: Icons.storefront_rounded,
      label: 'المتجر',
    );
    _customer ??= await _paintLabeledPin(
      fill: AppColors.navy,
      icon: Icons.home_rounded,
      label: 'التوصيل',
    );
    _motorcycle ??= await _paintMotorcycle(accent: AppColors.primary);
    _motorcycleAlt ??= await _paintMotorcycle(accent: AppColors.primaryDark);
  }

  static BitmapDescriptor get store =>
      _store ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);

  static BitmapDescriptor get customer =>
      _customer ??
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);

  static BitmapDescriptor get motorcycle =>
      _motorcycle ??
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);

  static BitmapDescriptor get motorcyclePulse =>
      _motorcycleAlt ?? motorcycle;

  static Future<BitmapDescriptor> _paintLabeledPin({
    required Color fill,
    required IconData icon,
    required String label,
  }) async {
    const width = 160.0;
    const height = 190.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = const Offset(width / 2, 72);

    // ظل
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center.translate(0, 4), 34, shadow);

    // دائرة اللون
    canvas.drawCircle(center, 34, Paint()..color = fill);
    canvas.drawCircle(
      center,
      34,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // أيقونة
    final tpIcon = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 30,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tpIcon.paint(
      canvas,
      Offset(center.dx - tpIcon.width / 2, center.dy - tpIcon.height / 2),
    );

    // سن الدبوس
    final tip = Path()
      ..moveTo(center.dx - 14, center.dy + 28)
      ..lineTo(center.dx + 14, center.dy + 28)
      ..lineTo(center.dx, center.dy + 52)
      ..close();
    canvas.drawPath(tip, Paint()..color = fill);

    // شارة التسمية
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0A0A0A),
          fontFamily: 'Cairo',
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    final badgeW = labelPainter.width + 28;
    final badgeH = labelPainter.height + 14;
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(width / 2, height - badgeH / 2 - 6),
        width: badgeW,
        height: badgeH,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = fill.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    labelPainter.paint(
      canvas,
      Offset(
        width / 2 - labelPainter.width / 2,
        height - badgeH / 2 - 6 - labelPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: width / 2.6,
      height: height / 2.6,
    );
  }

  static Future<BitmapDescriptor> _paintMotorcycle({
    required Color accent,
  }) async {
    const size = 128.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = const Offset(size / 2, size / 2);

    canvas.drawCircle(
      center.translate(0, 3),
      40,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(center, 40, Paint()..color = accent);
    canvas.drawCircle(
      center,
      40,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    final icon = Icons.two_wheeler_rounded;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 44,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2 - 1),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: size / 2.2,
      height: size / 2.2,
    );
  }

  /// اتجاه الحركة بالدرجات (0 = شمال) لتدوير علامة المندوب.
  static double bearingDegrees(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLng = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    final brng = math.atan2(y, x) * 180 / math.pi;
    return (brng + 360) % 360;
  }
}
