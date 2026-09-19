import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matlobgo/core/utils/catalog_image_diagnostics.dart';
import 'package:matlobgo/services/analytics_service.dart';
import 'package:matlobgo/services/cms_text_service.dart';
import 'package:matlobgo/web/services/web_analytics_service.dart';
import 'package:matlobgo/web/services/web_cart_service.dart';
import 'package:matlobgo/web/services/web_conversion_service.dart';
import 'package:matlobgo/web/services/web_governorate_service.dart';
import 'package:matlobgo/web/services/web_image_health_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bootstrapWeb() async {
  CatalogImageDiagnostics.enabled = kDebugMode ||
      bool.fromEnvironment('CATALOG_IMAGE_DEBUG', defaultValue: false);

  await WebGovernorateService.instance.init();
  await WebConversionService.instance.init();
  unawaited(CmsTextService.instance.start());

  WebCartService.instance.addListener(
    WebConversionService.instance.onCartChanged,
  );

  final prefs = await SharedPreferences.getInstance();
  var guestId = prefs.getString('web_guest_id');
  guestId ??= 'web_${DateTime.now().millisecondsSinceEpoch}';
  await prefs.setString('web_guest_id', guestId);

  AnalyticsService.instance.bindUser(
    userId: guestId,
    userName: 'زائر ويب',
  );

  unawaited(WebAnalyticsService.instance.webSessionStart());

  unawaited(WebImageHealthService.runStartupAuditIfEnabled());
}
