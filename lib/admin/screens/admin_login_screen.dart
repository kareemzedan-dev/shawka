import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/admin_auth_service.dart';
import 'package:matlobgo/admin/theme/admin_theme.dart';
import 'package:matlobgo/admin/widgets/admin_shell.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/widgets/brand_logo.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';

/// تسجيل دخول منفصل — يسمح فقط لحسابات role = admin.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AdminAuthService();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await _auth.signInAdmin(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminShell(user: user)),
      );
    } catch (e) {
      setState(() => _error = _auth.mapError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      body: Row(
        children: [
          if (wide) const Expanded(child: _AdminBrandingPane()),
          Expanded(
            flex: wide ? 1 : 2,
            child: ColoredBox(
              color: AdminTheme.surface,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!wide) ...[
                            const _AdminBrandingPane(compact: true),
                            const SizedBox(height: 32),
                          ],
                          Text(
                            'تسجيل دخول المسؤول',
                            style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'هذه الصفحة للمسؤولين فقط. حسابات العملاء والدليفري لا يمكنها الدخول.',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          PremiumInputField(
                            controller: _emailController,
                            label: 'البريد الإلكتروني',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'أدخل البريد'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          PremiumInputField(
                            controller: _passwordController,
                            label: 'كلمة المرور',
                            obscureText: true,
                            validator: (v) => v == null || v.length < 6
                                ? 'كلمة المرور قصيرة'
                                : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _error!,
                                style: GoogleFonts.cairo(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _loading ? null : _signIn,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.ink,
                              foregroundColor: AppColors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AdminTheme.radiusSm),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : Text(
                                    'دخول لوحة التحكم',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBrandingPane extends StatelessWidget {
  const _AdminBrandingPane({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.inkGradient,
      ),
      padding: EdgeInsets.all(compact ? 24 : 48),
      child: Column(
        mainAxisAlignment:
            compact ? MainAxisAlignment.start : MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandLogo(
            width: compact ? 120 : 168,
            style: BrandLogoStyle.standalone,
          ),
          SizedBox(height: compact ? 18 : 28),
          Text(
            AppBranding.displayName,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: compact ? 26 : 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppBranding.nameAr,
            style: GoogleFonts.cairo(
              color: AppColors.primaryLight,
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لوحة تحكم المسؤول',
            style: GoogleFonts.cairo(
              color: Colors.white70,
              fontSize: compact ? 15 : 17,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 36),
            _FeatureLine(Icons.storefront_rounded, 'إدارة الموردين وشركات توريد المواد الغذائية'),
            _FeatureLine(Icons.inventory_2_rounded, 'إدارة المنتجات لكل متجر'),
            _FeatureLine(Icons.tune_rounded, 'تحكم كامل في بيانات التطبيق'),
            _FeatureLine(Icons.cloud_rounded, 'قاعدة بيانات موحدة لكل المنصات'),
          ],
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
