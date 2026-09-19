import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/egyptian_phone.dart';
import 'package:matlobgo/core/widgets/auth_buttons.dart';
import 'package:matlobgo/core/widgets/auth_layout.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/screens/home/home_screen.dart';
import 'package:matlobgo/services/auth_service.dart';

/// للحسابات القديمة بدون كلمة مرور — OTP مرة واحدة لتعيين الباسورد.
class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _auth = AuthService();

  bool _otpSent = false;
  bool _loading = false;
  bool _obscure = true;
  String? _sessionId;
  String? _phoneE164;
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCooldown([int seconds = 60]) {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  Future<void> _sendOtp({bool resend = false}) async {
    if (!resend && !(_formKey.currentState?.validate() ?? false)) return;
    final e164 = EgyptianPhone.toE164(_phoneController.text);
    if (e164 == null) {
      showAuthMessage(context, 'رقم موبايل غير صحيح', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final session = await _auth.sendPhoneOtp(
        phoneRaw: e164,
        purpose: 'password_setup',
      );
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _sessionId = session.sessionId;
        _phoneE164 = session.phoneE164;
        _loading = false;
        if (session.isInApp) _otpController.text = session.inAppCode!;
      });
      _startResendCooldown();
      if (session.isInApp) await _submit();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showAuthMessage(context, _auth.mapAuthError(e), isError: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        showAuthMessage(context, 'تعذّر إرسال الرمز', isError: true);
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final sessionId = _sessionId;
    final phone = _phoneE164;
    if (sessionId == null || phone == null) {
      showAuthMessage(context, 'اطلب رمز التحقق أولاً', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.verifyPhoneOtp(
        phoneE164: phone,
        sessionId: sessionId,
        smsCode: _otpController.text.trim(),
      );
      await _auth.setCustomerCredentials(
        name: _nameController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (_) => false,
      );
      if (mounted) {
        showAuthMessage(context, 'تم حفظ كلمة المرور — يمكنك الدخول بها لاحقاً');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showAuthMessage(context, _auth.mapAuthError(e), isError: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        showAuthMessage(context, 'تعذّر حفظ كلمة المرور', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.lightStatusBar,
      child: Scaffold(
        backgroundColor: PremiumBackground.scaffoldColor(context),
        body: AuthLayout(
          showBackButton: true,
          title: 'تعيين كلمة مرور',
          subtitle: 'للحسابات التي أُنشئت قبل إضافة كلمة المرور',
          formChild: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumInputField(
                  label: 'الاسم',
                  controller: _nameController,
                  hint: 'اسمك',
                  leading: const FieldIcon(Icons.person_outline_rounded),
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'أدخل الاسم' : null,
                ),
                const SizedBox(height: 14),
                PremiumInputField(
                  label: 'رقم الموبايل',
                  controller: _phoneController,
                  hint: '01xxxxxxxxx',
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d+\s]')),
                    LengthLimitingTextInputFormatter(14),
                  ],
                  leading: const FieldIcon(Icons.phone_android_rounded),
                  validator: (v) {
                    if (v == null || !EgyptianPhone.isValid(v)) {
                      return 'رقم موبايل غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                PremiumInputField(
                  label: 'كلمة المرور الجديدة',
                  controller: _passwordController,
                  obscureText: _obscure,
                  textDirection: TextDirection.ltr,
                  leading: const FieldIcon(Icons.lock_outline_rounded),
                  trailing: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? '6 أحرف على الأقل' : null,
                ),
                if (_otpSent) ...[
                  const SizedBox(height: 14),
                  PremiumInputField(
                    label: 'رمز التحقق',
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    leading: const FieldIcon(Icons.sms_outlined),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: (_loading || _resendSeconds > 0)
                          ? null
                          : () => _sendOtp(resend: true),
                      child: Text(
                        _resendSeconds > 0
                            ? 'إعادة الإرسال ($_resendSeconds)'
                            : 'إعادة إرسال الرمز',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _otpSent ? 'حفظ كلمة المرور' : 'إرسال رمز التحقق',
                  isLoading: _loading,
                  onPressed: _otpSent ? _submit : () => _sendOtp(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
