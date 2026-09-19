import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/auth/customer_access.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/egyptian_phone.dart';
import 'package:matlobgo/core/widgets/auth_buttons.dart';
import 'package:matlobgo/core/widgets/auth_layout.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/screens/auth/set_password_screen.dart';
import 'package:matlobgo/screens/auth/signup_screen.dart';
import 'package:matlobgo/screens/home/home_screen.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.requireRealAccount = false});

  /// عند `true` يُخفى الدخول كضيف (مثلاً قبل إتمام الطلب).
  final bool requireRealAccount;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _config = AppConfigService.instance;

  bool _isLoading = false;
  bool _isGuestLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _config.addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    _config.removeListener(_onConfigChanged);
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onConfigChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _navigateAfterAuth() async {
    if (!mounted) return;
    if (widget.requireRealAccount) {
      Navigator.of(context).pop(true);
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithPhonePassword(
        phoneRaw: _phoneController.text,
        password: _passwordController.text,
      );
      final profile = await _authService.getCurrentAppUser();
      if (!mounted) return;

      final decision = CustomerAccess.decide(profile);
      switch (decision) {
        case CustomerAccessDecision.allow:
        case CustomerAccessDecision.allowApproved:
          setState(() => _isLoading = false);
          await _navigateAfterAuth();
          return;
        case CustomerAccessDecision.pendingReview:
          setState(() => _isLoading = false);
          if (widget.requireRealAccount) {
            if (mounted) {
              showAuthMessage(
                context,
                'حسابك قيد المراجعة — يمكنك التصفح لكن الطلب متاح بعد الموافقة',
                isError: true,
              );
            }
            return;
          }
          await _navigateAfterAuth();
          return;
        case CustomerAccessDecision.incompleteSignup:
          setState(() => _isLoading = false);
          if (widget.requireRealAccount) {
            await _authService.signOut();
            if (mounted) {
              showAuthMessage(
                context,
                CustomerAccess.denialMessage(decision),
                isError: true,
              );
            }
            return;
          }
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const SignUpScreen(resumeIncomplete: true),
            ),
          );
          return;
        case CustomerAccessDecision.rejected:
        case CustomerAccessDecision.disabled:
        case CustomerAccessDecision.missingProfile:
          await _authService.signOut();
          if (mounted) {
            setState(() => _isLoading = false);
            showAuthMessage(
              context,
              CustomerAccess.denialMessage(decision),
              isError: true,
            );
          }
          return;
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showAuthMessage(context, _authService.mapAuthError(e), isError: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        showAuthMessage(context, 'تعذّر تسجيل الدخول', isError: true);
      }
    }
  }

  Future<void> _handleGuestLogin() async {
    if (widget.requireRealAccount) {
      showAuthMessage(
        context,
        'لإتمام الطلب سجّل دخولك بحساب حقيقي',
        isError: true,
      );
      return;
    }
    if (!_config.settings.enableGuestCheckout) {
      showAuthMessage(
        context,
        'الدخول كضيف غير متاح حالياً — سجّل حسابك للمتابعة',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isGuestLoading = true);

    try {
      await _authService.signInAsGuest();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        showAuthMessage(context, _authService.mapAuthError(e), isError: true);
      }
    } catch (_) {
      if (mounted) {
        showAuthMessage(context, 'تعذّر الدخول كضيف', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isGuestLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowGuest =
        _config.settings.enableGuestCheckout && !widget.requireRealAccount;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.lightStatusBar,
      child: Scaffold(
        backgroundColor: PremiumBackground.scaffoldColor(context),
        resizeToAvoidBottomInset: true,
        body: AuthLayout(
          title: 'مرحباً بعودتك',
          subtitle: 'ادخل برقم الموبايل وكلمة المرور',
          formChild: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthSectionHeader(
                  title: 'تسجيل الدخول',
                  subtitle: 'بدون رمز تحقق — الرقم وكلمة المرور فقط',
                ),
                const SizedBox(height: 28),
                PremiumInputField(
                  label: 'رقم الموبايل',
                  controller: _phoneController,
                  hint: '01xxxxxxxxx',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d+\s]')),
                    LengthLimitingTextInputFormatter(14),
                  ],
                  leading: const FieldIcon(Icons.phone_android_rounded),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'من فضلك أدخل رقم الموبايل';
                    }
                    if (!EgyptianPhone.isValid(value)) {
                      return 'رقم موبايل مصري غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                PremiumInputField(
                  label: 'كلمة المرور',
                  controller: _passwordController,
                  hint: '••••••••',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  leading: const FieldIcon(Icons.lock_outline_rounded),
                  trailing: IconButton(
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  onFieldSubmitted: (_) => _handleLogin(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'أدخل كلمة المرور';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'رمز التحقق يُطلب فقط عند إنشاء حساب جديد',
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SetPasswordScreen(),
                              ),
                            );
                          },
                    child: Text(
                      'تعيين كلمة مرور للحساب (مرة واحدة)',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'تسجيل الدخول',
                  isLoading: _isLoading,
                  onPressed: _isGuestLoading ? null : _handleLogin,
                ),
                if (allowGuest) ...[
                  const SizedBox(height: 20),
                  const AuthDivider(),
                  const SizedBox(height: 20),
                  SecondaryButton(
                    label: 'الدخول كضيف',
                    icon: Icons.person_outline_rounded,
                    isLoading: _isGuestLoading,
                    onPressed: _isLoading ? null : _handleGuestLogin,
                  ),
                ],
              ],
            ),
          ),
          footer: AuthFooterCard(
            prompt: 'معندكش حساب؟',
            actionLabel: 'إنشاء حساب جديد',
            onAction: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SignUpScreen(
                    popOnSuccess: widget.requireRealAccount,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
