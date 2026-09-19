import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/widgets/auth_buttons.dart';
import 'package:matlobgo/core/widgets/auth_layout.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/screens/auth/login_screen.dart';
import 'package:matlobgo/screens/auth/signup_screen.dart';
import 'package:matlobgo/services/auth_service.dart';

/// يمنع إتمام الطلب للضيف ويوجّهه لتسجيل دخول حقيقي مع الإبقاء على السلة.
Future<AppUser?> requireRealAccountForCheckout(BuildContext context) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Icon(
                  Icons.lock_person_rounded,
                  size: 42,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'سجّل دخولك لإتمام الطلب',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تقدر تتصفح وتجهّز سلتك كضيف، لكن إتمام الطلب يحتاج حساباً حقيقياً.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    height: 1.55,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'تسجيل الدخول',
                  onPressed: () => Navigator.of(ctx).pop('login'),
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: 'إنشاء حساب جديد',
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: () => Navigator.of(ctx).pop('signup'),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop('cancel'),
                  child: Text(
                    'متابعة التصفح',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  if (choice != 'login' && choice != 'signup') return null;
  if (!context.mounted) return null;

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => choice == 'signup'
          ? const SignUpScreen(popOnSuccess: true)
          : const LoginScreen(requireRealAccount: true),
    ),
  );

  if (!context.mounted) return null;
  final user = await AuthService().getCurrentAppUser();
  if (user == null || user.isGuest) return null;
  return user;
}

/// يمنع إتمام الطلب للحسابات قيد مراجعة الأدمن.
Future<void> showPendingApprovalSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Icon(
                  Icons.hourglass_top_rounded,
                  size: 42,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'حسابك قيد المراجعة',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تقدر تتصفح المنتجات وتجهّز سلتك عادي، '
                  'لكن تأكيد الطلب متاح بعد موافقة الأدمن على توثيق حسابك.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    height: 1.55,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'حسناً، متابعة التصفح',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// بوابة موحّدة قبل فتح/تأكيد الدفع: حساب حقيقي + معتمد.
Future<AppUser?> ensureApprovedAccountForCheckout(BuildContext context) async {
  var user = await AuthService().getCurrentAppUser();
  if (!context.mounted) return null;
  if (user == null || user.isGuest) {
    user = await requireRealAccountForCheckout(context);
    if (user == null || !context.mounted) return null;
    // أعد الجلب بعد التسجيل/الدخول
    user = await AuthService().getCurrentAppUser();
  }
  if (!context.mounted) return null;
  if (user == null || user.isGuest) return null;

  if (user.isCustomerPendingApproval) {
    if (!context.mounted) return null;
    await showPendingApprovalSheet(context);
    return null;
  }

  if (!user.isCustomerApprovedForApp) {
    if (!context.mounted) return null;
    showAuthMessage(
      context,
      'حسابك غير مفعّل حالياً — تواصل مع الدعم',
      isError: true,
    );
    return null;
  }

  return user;
}
