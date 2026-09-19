import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/firebase/messaging_setup_stub.dart'
    if (dart.library.io) 'package:matlobgo/core/firebase/messaging_setup_mobile.dart';
import 'package:matlobgo/core/media/android_photo_picker.dart';
import 'package:matlobgo/core/di/service_locator.dart';
import 'package:matlobgo/core/maps/maps_api_key.dart';
import 'package:matlobgo/core/firestore/firestore_bootstrap.dart';
import 'package:matlobgo/core/navigation/startup_navigation.dart';
import 'package:matlobgo/core/theme/app_theme.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/core/utils/catalog_warmup_service.dart';
import 'package:matlobgo/core/utils/startup_timing.dart';
import 'package:matlobgo/firebase_options.dart';
import 'package:matlobgo/screens/splash/splash_screen.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/services/auth_service.dart';
import 'package:matlobgo/services/cms_text_service.dart';
import 'package:matlobgo/services/favorites_service.dart';
import 'package:matlobgo/services/push_notification_service.dart';
import 'package:matlobgo/services/service_area_service.dart';
import 'package:matlobgo/services/theme_service.dart';
import 'package:matlobgo/web/bootstrap/web_bootstrap.dart';
import 'package:matlobgo/web/web_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureAndroidPhotoPicker();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  PaintingBinding.instance.imageCache.maximumSize = 80;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20;
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('[Uncaught] $error\n$stack');
    }
    return true;
  };
  StartupTiming.start();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  unawaited(AuthService().configurePhoneAuthForInApp());
  await ServiceLocator.init();
  AppConfigService.instance.start();

  if (kIsWeb) {
    runApp(const MatlobGoWebApp());
    unawaited(_completeWebInit());
    return;
  }

  await FirestoreBootstrap.init();
  await MapsApiKey.warmUp();
  registerFirebaseMessagingBackgroundHandler();

  await Future.wait([
    ThemeService.instance.init(),
    FavoritesService.instance.init(),
    PushNotificationService.instance.init(),
    ServiceAreaService.instance.init(),
  ]);

  unawaited(CmsTextService.instance.start());
  unawaited(_warmCatalogForCachedArea());
  runApp(const MatlobGoApp());
}

Future<void> _completeWebInit() async {
  try {
    await FirestoreBootstrap.init();
    await bootstrapWeb();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[WebInit] $e\n$st');
    }
  }
}

Future<void> _warmCatalogForCachedArea() async {
  final area = ServiceAreaService.instance;
  if (area.canEnterAppImmediately && area.governorate != null) {
    await CatalogWarmupService.instance
        .warmForGovernorate(area.governorate!.name);
  } else {
    unawaited(CatalogWarmupService.instance.warmDefault());
  }
}

class MatlobGoApp extends StatelessWidget {
  const MatlobGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          title: AppBranding.shortName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeService.instance.themeMode,
          locale: const Locale('ar'),
          builder: (context, child) {
            final premium = PremiumBackground.isEnabled(context);
            return Directionality(
              textDirection: TextDirection.rtl,
              child: premium
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        const Positioned.fill(
                          child: PremiumBackgroundBackdrop(),
                        ),
                        child ?? const SizedBox.shrink(),
                      ],
                    )
                  : child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
