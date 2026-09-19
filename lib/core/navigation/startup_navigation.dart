import 'package:flutter/material.dart';
import 'package:matlobgo/core/auth/customer_access.dart';
import 'package:matlobgo/core/utils/startup_timing.dart';
import 'package:matlobgo/screens/auth/login_screen.dart';
import 'package:matlobgo/screens/auth/signup_screen.dart';
import 'package:matlobgo/screens/home/home_screen.dart';
import 'package:matlobgo/screens/service_area/service_area_onboarding_screen.dart';
import 'package:matlobgo/screens/service_area/service_area_unsupported_screen.dart';
import 'package:matlobgo/services/auth_service.dart';
import 'package:matlobgo/services/service_area_service.dart';

/// Root navigator for flows that outlive the splash route (e.g. service-area onboarding).
final rootNavigatorKey = GlobalKey<NavigatorState>();

class StartupNavigation {
  const StartupNavigation._();

  static Future<void> navigateAfterInit({
    required bool isLoggedIn,
    BuildContext? context,
  }) async {
    final navContext = context ?? rootNavigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return;

    final area = ServiceAreaService.instance;

    if (!area.onboardingComplete) {
      await _replaceWith(
        navContext,
        ServiceAreaOnboardingScreen(
          onComplete: () => navigateAfterInit(isLoggedIn: isLoggedIn),
        ),
      );
      return;
    }

    // Geo لم يعد يمنع الدخول — الحظر محصور بـ Delivery عند Checkout.
    // نبقي الفحص كحماية مستقبلية إن تغيّر المعنى.
    if (area.isBlocked) {
      await _replaceWith(
        navContext,
        ServiceAreaUnsupportedScreen(
          onUnblocked: () => navigateAfterInit(isLoggedIn: isLoggedIn),
        ),
      );
      return;
    }

    Widget nextScreen = const LoginScreen();

    if (isLoggedIn) {
      final auth = AuthService();
      final user = await auth.getCurrentAppUser();
      final decision = CustomerAccess.decide(user);

      switch (decision) {
        case CustomerAccessDecision.allow:
        case CustomerAccessDecision.allowApproved:
        case CustomerAccessDecision.pendingReview:
          nextScreen = const HomeScreen();
          break;
        case CustomerAccessDecision.incompleteSignup:
          nextScreen = const SignUpScreen(resumeIncomplete: true);
          break;
        case CustomerAccessDecision.rejected:
        case CustomerAccessDecision.disabled:
        case CustomerAccessDecision.missingProfile:
          await auth.signOut();
          nextScreen = const LoginScreen();
          break;
      }
    }

    if (!navContext.mounted) return;
    await _replaceWith(navContext, nextScreen);
    StartupTiming.mark('home_ready');
  }

  static Future<void> _replaceWith(
    BuildContext context,
    Widget nextScreen,
  ) async {
    if (!context.mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }
}
