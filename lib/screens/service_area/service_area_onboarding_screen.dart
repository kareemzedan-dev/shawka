import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/services/location_service.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/catalog_warmup_service.dart';
import 'package:matlobgo/core/utils/startup_timing.dart';
import 'package:matlobgo/core/widgets/auth_buttons.dart';
import 'package:matlobgo/core/widgets/brand_logo.dart';
import 'package:matlobgo/services/service_area_service.dart';

/// شاشة ترحيب أول تشغيل — تحديد سريع + دخول فوري.
class ServiceAreaOnboardingScreen extends StatefulWidget {
  const ServiceAreaOnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<ServiceAreaOnboardingScreen> createState() =>
      _ServiceAreaOnboardingScreenState();
}

class _ServiceAreaOnboardingScreenState
    extends State<ServiceAreaOnboardingScreen>
    with TickerProviderStateMixin {
  final _service = ServiceAreaService.instance;
  late final AnimationController _pulseController;
  late final AnimationController _successController;

  bool _detecting = false;
  bool _showSuccess = false;
  String? _successGovernorate;
  String? _localError;

  static const _successFlashMs = 450;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _service.addListener(_onServiceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startDetection());
    });
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _startDetection() async {
    if (_detecting) return;
    setState(() {
      _detecting = true;
      _localError = null;
      _showSuccess = false;
    });

    StartupTiming.mark('onboarding_detect_start');
    final phase = await _service.detectFromGps(
      useCachedOnTimeout: false,
      preferFreshGps: false,
      gpsTimeout: const Duration(seconds: 12),
      geocodeTimeout: const Duration(seconds: 5),
    );

    if (!mounted) return;

    switch (phase) {
      case ServiceAreaPhase.supported:
        final name = _service.governorate?.name ?? '';
        StartupTiming.mark('onboarding_detect_done');
        unawaited(CatalogWarmupService.instance.warmForGovernorate(name));
        setState(() {
          _detecting = false;
          _showSuccess = true;
          _successGovernorate = name;
        });
        unawaited(_successController.forward(from: 0));
        await Future<void>.delayed(
          const Duration(milliseconds: _successFlashMs),
        );
        if (mounted) widget.onComplete();
      case ServiceAreaPhase.browsing:
      case ServiceAreaPhase.unsupported:
        // unsupported لم يعد يحظر التطبيق — نكمل كتصفح.
        StartupTiming.mark('onboarding_detect_done');
        unawaited(
          CatalogWarmupService.instance.warmForGovernorate(
            _service.browsingCatalogGovernorate.name,
          ),
        );
        setState(() => _detecting = false);
        widget.onComplete();
      case ServiceAreaPhase.error:
        setState(() {
          _detecting = false;
          _localError = _service.friendlyError;
        });
      default:
        setState(() => _detecting = false);
    }
  }

  Future<void> _continueWithoutLocation() async {
    setState(() {
      _detecting = true;
      _localError = null;
    });
    await _service.completeAsBrowsingFallback();
    if (!mounted) return;
    setState(() => _detecting = false);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.navy,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.splashGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(
                                alpha: 0.25 * _pulseController.value,
                              ),
                              blurRadius: 48,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: const BrandLogo(
                      width: 120,
                      style: BrandLogoStyle.onDark,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _showSuccess
                        ? 'تم تحديد موقعك'
                        : 'مرحباً بك في ${AppBranding.shortName}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.white.withValues(alpha: 0.72),
                    ),
                  ),
                  if (_showSuccess && _successGovernorate != null) ...[
                    const SizedBox(height: 20),
                    ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _successController,
                        curve: Curves.easeOutBack,
                      ),
                      child: FadeTransition(
                        opacity: _successController,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _successGovernorate!,
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(flex: 2),
                  if (_detecting)
                    Column(
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary.withValues(alpha: 0.95),
                            ),
                            backgroundColor: AppColors.white.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'جاري تحديد موقعك…',
                          style: GoogleFonts.cairo(
                            color: AppColors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  else if (!_showSuccess) ...[
                    PrimaryButton(
                      label: 'تحديد موقعي',
                      onPressed: _startDetection,
                    ),
                    if (_service.errorKind ==
                            ServiceAreaErrorKind.permissionDeniedForever ||
                        _service.errorKind ==
                            ServiceAreaErrorKind.locationDisabled) ...[
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label:
                            _service.errorKind ==
                                ServiceAreaErrorKind.locationDisabled
                            ? 'فتح إعدادات الموقع'
                            : 'فتح إعدادات التطبيق',
                        onPressed: () {
                          if (_service.errorKind ==
                              ServiceAreaErrorKind.locationDisabled) {
                            unawaited(
                              LocationService.instance.openLocationSettings(),
                            );
                          } else {
                            unawaited(
                              LocationService.instance.openAppSettings(),
                            );
                          }
                        },
                      ),
                    ],
                    if (_localError != null ||
                        _service.errorKind != ServiceAreaErrorKind.none) ...[
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'متابعة التصفح بدون موقع',
                        onPressed: _continueWithoutLocation,
                      ),
                    ],
                    if (_localError != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _localError!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    if (_showSuccess) return 'جاري فتح التطبيق…';
    if (_service.errorKind == ServiceAreaErrorKind.permissionDenied ||
        _service.errorKind == ServiceAreaErrorKind.permissionDeniedForever) {
      return 'يمكنك متابعة التصفح بدون موقع، وتحديد عنوان التوصيل لاحقاً عند الطلب';
    }
    if (_service.errorKind == ServiceAreaErrorKind.locationDisabled) {
      return 'فعّل خدمة الموقع أو تابع التصفح بدون موقع وحدد عنوانك عند الطلب';
    }
    if (_localError != null) {
      return 'يمكنك إعادة المحاولة أو متابعة التصفح بدون موقع الآن';
    }
    return 'نحدد موقعك تلقائياً لعرض المتاجر والعروض المناسبة لمنطقتك';
  }
}
