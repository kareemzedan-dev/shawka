import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/egyptian_phone.dart';
import 'package:matlobgo/core/widgets/auth_buttons.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/screens/auth/login_screen.dart';
import 'package:matlobgo/screens/home/home_screen.dart';
import 'package:matlobgo/services/auth_service.dart';

/// شاشة انتظار موافقة الأدمن بعد تسجيل العميل بصورة الإثبات.
class AccountPendingScreen extends StatefulWidget {
  const AccountPendingScreen({super.key, this.initialUser});

  final AppUser? initialUser;

  @override
  State<AccountPendingScreen> createState() => _AccountPendingScreenState();
}

class _AccountPendingScreenState extends State<AccountPendingScreen> {
  final _auth = AuthService();
  AppUser? _user;
  bool _checking = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    unawaited(_refresh());
    _poll = Timer.periodic(const Duration(seconds: 12), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final user = await _auth.getCurrentAppUser();
      if (!mounted) return;
      if (user != null && user.isCustomerApprovedForApp) {
        _poll?.cancel();
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
          (_) => false,
        );
        return;
      }
      if (user != null &&
          (user.customerApprovalStatus == 'rejected' ||
              user.isCustomerSignupIncomplete)) {
        _poll?.cancel();
        await _signOut();
        return;
      }
      setState(() => _user = user);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final phone = user != null && user.phone.isNotEmpty
        ? EgyptianPhone.toLocalDisplay(user.phone)
        : '—';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.lightStatusBar,
      child: Scaffold(
        backgroundColor: PremiumBackground.scaffoldColor(context),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    size: 42,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'حسابك تحت المراجعة',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'استلمنا طلبك وصورة إثبات المكان.\n'
                  'فريق Shawka هيراجع بياناتك ويفعّل الحساب قريباً.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    height: 1.65,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(label: 'الموبايل', value: phone),
                      if (user != null && user.activityTypeName.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _InfoRow(
                          label: 'نوع النشاط',
                          value: user.activityTypeName,
                        ),
                      ],
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'الحالة',
                        value: 'بانتظار الموافقة',
                        valueColor: AppColors.primaryDark,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'تحديث الحالة',
                  isLoading: _checking,
                  onPressed: _refresh,
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'تسجيل الخروج',
                  icon: Icons.logout_rounded,
                  onPressed: _checking ? null : _signOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
