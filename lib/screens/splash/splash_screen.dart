import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/navigation/startup_navigation.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/catalog_warmup_service.dart';
import 'package:matlobgo/core/utils/startup_timing.dart';
import 'package:matlobgo/core/widgets/brand_logo.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/services/auth_service.dart';
import 'package:matlobgo/services/service_area_service.dart';

/// Premium enterprise splash — logo-only, phased animation, dark-mode aware.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _minVisibleMs = 1500;
  static const _exitFadeMs = 380;

  late final AnimationController _introController;
  late final AnimationController _glowController;
  late final AnimationController _progressController;
  late final AnimationController _exitController;

  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;
  late final Animation<double> _glowPulse;
  late final Animation<double> _loaderFade;
  late final Animation<double> _exitOpacity;

  bool _bootstrapDone = false;
  bool _minTimeElapsed = false;
  bool _exiting = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    unawaited(_runBootstrap());
    Future<void>.delayed(const Duration(milliseconds: _minVisibleMs), () {
      if (!mounted) return;
      setState(() => _minTimeElapsed = true);
      _tryExit();
    });
  }

  void _setupAnimations() {
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _exitFadeMs),
    );

    _fadeIn = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _glowPulse = Tween<double>(begin: 0.22, end: 0.48).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _loaderFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );

    unawaited(_introController.forward());
    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _glowController.repeat(reverse: true);
      }
    });
  }

  Future<void> _runBootstrap() async {
    StartupTiming.mark('splash_visible');

    final authService = AuthService();
    final authCheck = () async {
      var isLoggedIn = authService.currentUser != null;
      if (isLoggedIn) {
        final user = await authService.getCurrentAppUser();
        if (user?.isGuest == true &&
            !AppConfigService.instance.settings.enableGuestCheckout) {
          await authService.signOut();
          isLoggedIn = false;
        }
      }
      return isLoggedIn;
    }();

    final isLoggedIn = await authCheck;
    if (!mounted) return;

    final area = ServiceAreaService.instance;
    unawaited(area.refreshLocationInBackground());
    if (area.canEnterAppImmediately) {
      unawaited(
        CatalogWarmupService.instance.warmForGovernorate(area.governorate!.name),
      );
    }

    _isLoggedIn = isLoggedIn;
    _bootstrapDone = true;
    StartupTiming.mark('splash_navigate');
    _tryExit();
  }

  Future<void> _tryExit() async {
    if (_exiting || !_bootstrapDone || !_minTimeElapsed) return;
    _exiting = true;

    await _exitController.forward();
    if (!mounted) return;

    await StartupNavigation.navigateAfterInit(
      isLoggedIn: _isLoggedIn,
      context: context,
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _glowController.dispose();
    _progressController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = AppColors.splashGradientFor(isDark);
    final navBarColor = isDark ? AppColors.black : AppColors.navy;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: navBarColor,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: AnimatedBuilder(
            animation: _exitOpacity,
            builder: (context, child) {
              return Opacity(opacity: _exitOpacity.value, child: child);
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(gradient: gradient),
              child: SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 4),
                    _buildLogoCore(),
                    const Spacer(flex: 3),
                    _buildLoader(isDark),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoCore() {
    return AnimatedBuilder(
      animation: Listenable.merge([_introController, _glowController]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeIn.value,
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _glowPulse,
            builder: (context, _) {
              return Container(
                width: 460,
                height: 460,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: _glowPulse.value * 0.32),
                      blurRadius: 52,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              );
            },
          ),
          const BrandLogo(
            width: 340,
            style: BrandLogoStyle.standalone,
          ),
        ],
      ),
    );
  }

  Widget _buildLoader(bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([_loaderFade, _progressController]),
      builder: (context, _) {
        return Opacity(
          opacity: _loaderFade.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                height: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    children: [
                      Container(
                        color: AppColors.white.withValues(alpha: 0.12),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: 0.35 +
                              0.45 * _progressController.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.5),
                                  AppColors.primary,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppBranding.loadingMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withValues(
                        alpha: isDark ? 0.55 : 0.65,
                      ),
                      letterSpacing: 0.3,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
