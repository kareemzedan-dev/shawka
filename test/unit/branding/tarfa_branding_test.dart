import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/config/branding/branding.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

void main() {
  test('AppBranding display constants come from Branding.current', () {
    expect(AppBranding.shortName, Branding.current.shortName);
    expect(AppBranding.displayName, 'شوكة و سكينة');
    expect(AppBranding.displayName, isNot(contains('Shawka | Skeena')));
    expect(AppBranding.loadingMessage, isNotEmpty);
  });

  test('Splash gradients support light and dark', () {
    expect(AppColors.splashGradientFor(false), AppColors.splashGradient);
    expect(AppColors.splashGradientFor(true), AppColors.splashGradientDark);
    expect(AppColors.splashGradient.colors.last, AppColors.black);
  });
}
