import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/egyptian_phone.dart';
import 'package:matlobgo/core/utils/image_compressor.dart';
import 'package:matlobgo/core/widgets/auth_buttons.dart';
import 'package:matlobgo/core/widgets/auth_layout.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/models/customer_activity_type.dart';
import 'package:matlobgo/repositories/customer_activity_type_repository.dart';
import 'package:matlobgo/screens/auth/login_screen.dart';
import 'package:matlobgo/screens/home/home_screen.dart';
import 'package:matlobgo/screens/auth/widgets/activity_type_picker.dart';
import 'package:matlobgo/services/auth_service.dart';
import 'package:matlobgo/services/image_upload_service.dart';

enum _SignUpStep { credentials, otp, activity, proof }

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    this.popOnSuccess = false,
    this.resumeIncomplete = false,
  });

  final bool popOnSuccess;
  /// استكمال تسجيل توقّف بعد OTP (جلسة مصادقة موجودة).
  final bool resumeIncomplete;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _addressController = TextEditingController();
  final _authService = AuthService();
  final _activityRepo = CustomerActivityTypeRepository();
  final _imageUpload = ImageUploadService();
  final _picker = ImagePicker();

  _SignUpStep _step = _SignUpStep.credentials;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _otpSessionId;
  String? _phoneE164;
  CustomerActivityType? _selectedActivity;
  Uint8List? _proofBytes;
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    _activityRepo.seedDefaultsIfNeeded();
    if (widget.resumeIncomplete) {
      unawaited(_prepareResumeIncomplete());
    }
  }

  Future<void> _prepareResumeIncomplete() async {
    final user = await _authService.getCurrentAppUser();
    final authUser = _authService.currentUser;
    if (!mounted) return;
    if (authUser == null || user == null || !user.isCustomerSignupIncomplete) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    _nameController.text = user.name;
    final phone = user.phone.isNotEmpty
        ? user.phone
        : (authUser.phoneNumber ?? '');
    _phoneE164 = EgyptianPhone.toE164(phone) ?? phone;
    if (_phoneE164 != null && _phoneE164!.isNotEmpty) {
      _phoneController.text = EgyptianPhone.toLocalDisplay(_phoneE164!);
    }
    if (user.activityTypeId.isNotEmpty) {
      _selectedActivity = CustomerActivityType(
        id: user.activityTypeId,
        name: user.activityTypeName.isNotEmpty
            ? user.activityTypeName
            : user.activityTypeId,
      );
      _step = _SignUpStep.proof;
    } else {
      _step = _SignUpStep.activity;
    }
    if (user.address.isNotEmpty) {
      _addressController.text = user.address;
    }
    setState(() {});
  }

  Future<void> _leaveToLogin() async {
    // أي خروج من شاشة التسجيل مع جلسة مفتوحة يُغلق الحساب غير المكتمل.
    if (_authService.currentUser != null) {
      await _authService.signOut();
    }
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _addressController.dispose();
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

  Future<void> _finishSuccess() async {
    if (!mounted) return;
    if (widget.popOnSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const HomeScreen(),
      ),
      (_) => false,
    );
  }

  Future<void> _sendOtp({bool resend = false}) async {
    if (!resend && !(_formKey.currentState?.validate() ?? false)) return;

    final e164 = EgyptianPhone.toE164(_phoneController.text);
    if (e164 == null) {
      showAuthMessage(context, 'أدخل رقم موبايل مصري صحيح', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final session = await _authService.sendPhoneOtp(
        phoneRaw: e164,
        purpose: 'signup',
      );
      if (!mounted) return;
      setState(() {
        _otpSessionId = session.sessionId;
        _phoneE164 = session.phoneE164;
        _step = _SignUpStep.otp;
        _isLoading = false;
        if (session.isInApp) {
          _otpController.text = session.inAppCode!;
        }
      });
      _startResendCooldown();
      if (session.isInApp) {
        await _verifyOtp();
        return;
      }
      showAuthMessage(context, 'تم إرسال رمز التحقق');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showAuthMessage(context, _authService.mapAuthError(e), isError: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        showAuthMessage(context, 'تعذّر إرسال رمز التحقق', isError: true);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      showAuthMessage(
        context,
        'أدخل رمز التحقق المكوّن من 6 أرقام',
        isError: true,
      );
      return;
    }
    final sessionId = _otpSessionId;
    final phone = _phoneE164;
    if (sessionId == null || phone == null) {
      showAuthMessage(context, 'أعد طلب رمز التحقق', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await _authService.verifyPhoneOtp(
        phoneE164: phone,
        sessionId: sessionId,
        smsCode: code,
      );
      await _authService.setCustomerCredentials(
        name: _nameController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() {
        _step = _SignUpStep.activity;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showAuthMessage(context, _authService.mapAuthError(e), isError: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        showAuthMessage(context, 'تعذّر التحقق من الرمز', isError: true);
      }
    }
  }

  void _continueToProof() {
    if (_selectedActivity == null) {
      showAuthMessage(context, 'اختر نوع النشاط', isError: true);
      return;
    }
    setState(() => _step = _SignUpStep.proof);
  }

  /// Force-refresh the Firebase ID token, or re-login with password if needed.
  Future<void> _ensureFreshAuth(String phone) async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        await user.getIdToken(true);
        return;
      } catch (_) {
        // Token refresh failed — fall through to password re-login.
      }
    }
    final pw = _passwordController.text;
    if (pw.isNotEmpty) {
      try {
        await _authService.signInWithPhonePassword(
          phoneRaw: phone,
          password: pw,
        );
      } catch (_) {}
    }
  }

  bool _validateAddress() {
    final address = _addressController.text.trim();
    if (address.length < 10) {
      showAuthMessage(
        context,
        'أدخل العنوان بالتفصيل (10 أحرف على الأقل)',
        isError: true,
      );
      return false;
    }
    return true;
  }

  Future<void> _pickProof(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2000,
      );
      if (file == null) return;
      final raw = await file.readAsBytes();
      final compressed =
          ImageCompressor.compress(raw, ImageUploadKind.customerProof);
      if (!mounted) return;
      setState(() => _proofBytes = compressed.bytes);
    } catch (_) {
      if (mounted) {
        showAuthMessage(context, 'تعذّر اختيار الصورة', isError: true);
      }
    }
  }

  Future<void> _completeRegistration() async {
    final activity = _selectedActivity;
    final phone = _phoneE164;
    final proof = _proofBytes;
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    if (activity == null) {
      showAuthMessage(context, 'اختر نوع النشاط', isError: true);
      return;
    }
    if (phone == null) {
      showAuthMessage(context, 'أعد إدخال رقم الموبايل', isError: true);
      return;
    }
    if (!_validateAddress()) return;
    if (proof == null || proof.isEmpty) {
      showAuthMessage(
        context,
        'رفع صورة إثبات المكان إلزامي',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Ensure a valid auth token before any Firebase call.
      await _ensureFreshAuth(phone);
      if (_authService.currentUser == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          showAuthMessage(context, 'انتهت الجلسة — أعد تسجيل الدخول', isError: true);
        }
        return;
      }

      final uploaded = await _imageUpload.uploadCustomerProof(
        userId: _authService.currentUser!.uid,
        bytes: proof,
      );
      await _authService.completePhoneCustomerProfile(
        phoneE164: phone,
        activityType: activity,
        proofImageUrl: uploaded.fullUrl,
        proofImageThumbUrl: uploaded.thumbUrl,
        displayName: name,
        address: address,
      );
      await _finishSuccess();
    } on FirebaseException catch (e) {
      if (mounted) {
        debugPrint('[Signup] FirebaseException: ${e.code} — ${e.message}');
        showAuthMessage(
          context,
          e.code == 'permission-denied'
              ? 'تعذّر حفظ ملفك — تحقق من الاتصال وحاول مرة أخرى'
              : 'حدث خطأ أثناء إنشاء الحساب',
          isError: true,
        );
      }
    } on StateError catch (_) {
      if (mounted) {
        showAuthMessage(context, 'انتهت الجلسة — أعد تسجيل الدخول', isError: true);
      }
    } catch (e) {
      if (mounted) {
        debugPrint('[Signup] Error: $e');
        showAuthMessage(context, 'حدث خطأ أثناء إنشاء الحساب', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leaveToLogin();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.lightStatusBar,
      child: Scaffold(
        backgroundColor: PremiumBackground.scaffoldColor(context),
        resizeToAvoidBottomInset: true,
        body: AuthLayout(
          showBackButton: true,
          title: AppBranding.joinPageTitle,
          subtitle: 'أنشئ حسابك بالاسم ورقم الموبايل وكلمة المرور',
          formChild: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthSectionHeader(
                  title: 'إنشاء حساب',
                  subtitle: switch (_step) {
                    _SignUpStep.credentials =>
                      'الاسم ورقم الموبايل وكلمة المرور',
                    _SignUpStep.otp => 'أدخل رمز التحقق مرة واحدة عند إنشاء الحساب',
                    _SignUpStep.activity => 'اختر نوع نشاطك',
                    _SignUpStep.proof =>
                      'العنوان بالتفصيل + صورة إثبات المكان',
                  },
                ),
                const SizedBox(height: 28),
                if (_step == _SignUpStep.credentials) ..._credentialsStep(),
                if (_step == _SignUpStep.otp) ..._otpStep(),
                if (_step == _SignUpStep.activity) ..._activityStep(),
                if (_step == _SignUpStep.proof) ..._proofStep(),
              ],
            ),
          ),
          footer: AuthFooterCard(
            prompt: 'عندك حساب بالفعل؟',
            actionLabel: 'تسجيل الدخول',
            onAction: () => unawaited(_leaveToLogin()),
          ),
        ),
      ),
      ),
    );
  }

  List<Widget> _credentialsStep() {
    return [
      PremiumInputField(
        label: 'الاسم',
        controller: _nameController,
        hint: 'اسمك أو اسم المكان',
        textInputAction: TextInputAction.next,
        leading: const FieldIcon(Icons.person_outline_rounded),
        validator: (value) {
          final v = value?.trim() ?? '';
          if (v.length < 2) return 'أدخل الاسم (حرفين على الأقل)';
          return null;
        },
      ),
      const SizedBox(height: 14),
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
        hint: '6 أحرف على الأقل',
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.next,
        textDirection: TextDirection.ltr,
        leading: const FieldIcon(Icons.lock_outline_rounded),
        trailing: IconButton(
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        validator: (value) {
          if (value == null || value.length < 6) {
            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
          }
          return null;
        },
      ),
      const SizedBox(height: 14),
      PremiumInputField(
        label: 'تأكيد كلمة المرور',
        controller: _confirmPasswordController,
        hint: 'أعد كتابة كلمة المرور',
        obscureText: _obscureConfirm,
        textInputAction: TextInputAction.done,
        textDirection: TextDirection.ltr,
        leading: const FieldIcon(Icons.lock_rounded),
        trailing: IconButton(
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          icon: Icon(
            _obscureConfirm
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        onFieldSubmitted: (_) => _sendOtp(),
        validator: (value) {
          if (value != _passwordController.text) {
            return 'كلمتا المرور غير متطابقتين';
          }
          return null;
        },
      ),
      const SizedBox(height: 12),
      Text(
        'سنرسل رمز تحقق مرة واحدة لتأكيد رقم الموبايل عند إنشاء الحساب فقط',
        style: GoogleFonts.cairo(
          fontSize: 12.5,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 28),
      PrimaryButton(
        label: 'متابعة والتحقق من الموبايل',
        isLoading: _isLoading,
        onPressed: () => _sendOtp(),
      ),
    ];
  }

  List<Widget> _otpStep() {
    final display = _phoneE164 != null
        ? EgyptianPhone.toLocalDisplay(_phoneE164!)
        : '';
    return [
      Text(
        'التحقق لـ $display',
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 20),
      PremiumInputField(
        label: 'رمز التحقق',
        controller: _otpController,
        hint: '••••••',
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        textDirection: TextDirection.ltr,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        leading: const FieldIcon(Icons.sms_outlined),
        onFieldSubmitted: (_) => _verifyOtp(),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          TextButton(
            onPressed: _isLoading
                ? null
                : () => setState(() {
                      _step = _SignUpStep.credentials;
                      _otpController.clear();
                    }),
            child: Text(
              'تعديل البيانات',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: (_isLoading || _resendSeconds > 0)
                ? null
                : () => _sendOtp(resend: true),
            child: Text(
              _resendSeconds > 0
                  ? 'إعادة الإرسال ($_resendSeconds)'
                  : 'إعادة إرسال الرمز',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      PrimaryButton(
        label: 'تأكيد الرمز',
        isLoading: _isLoading,
        onPressed: _verifyOtp,
      ),
    ];
  }

  List<Widget> _activityStep() {
    return [
      StreamBuilder<List<CustomerActivityType>>(
        stream: _activityRepo.watchActive(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final remote = snapshot.data ?? const <CustomerActivityType>[];
          final types = remote.isNotEmpty
              ? remote
              : CustomerActivityTypeDefaults.entries;
          return ActivityTypePicker(
            types: types,
            selectedId: _selectedActivity?.id,
            onSelected: (t) => setState(() => _selectedActivity = t),
          );
        },
      ),
      const SizedBox(height: 28),
      PrimaryButton(
        label: 'التالي',
        isLoading: false,
        onPressed: _continueToProof,
      ),
    ];
  }

  List<Widget> _proofStep() {
    return [
      PremiumInputField(
        label: 'العنوان بالتفصيل *',
        controller: _addressController,
        hint: 'المحافظة، المدينة، الشارع، رقم المبنى، علامة مميزة…',
        keyboardType: TextInputType.streetAddress,
        textInputAction: TextInputAction.next,
        minLines: 3,
        maxLines: 5,
        leading: const FieldIcon(Icons.location_on_outlined),
        validator: (value) {
          final v = value?.trim() ?? '';
          if (v.length < 10) {
            return 'أدخل العنوان بالتفصيل (10 أحرف على الأقل)';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      Text(
        'صورة واضحة لواجهة المكان أو لوحة المحل — مطلوبة للمراجعة',
        style: GoogleFonts.cairo(
          fontSize: 13,
          height: 1.5,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 16),
      AspectRatio(
        aspectRatio: 4 / 3,
        child: Material(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: _proofBytes == null
              ? InkWell(
                  onTap: _isLoading
                      ? null
                      : () => _pickProof(ImageSource.gallery),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 42,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'اضغط لرفع صورة الإثبات',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_proofBytes!, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _proofBytes = null),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  _isLoading ? null : () => _pickProof(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text('كاميرا', style: GoogleFonts.cairo()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  _isLoading ? null : () => _pickProof(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text('المعرض', style: GoogleFonts.cairo()),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: _isLoading
            ? null
            : () => setState(() => _step = _SignUpStep.activity),
        child: Text(
          'رجوع لاختيار النشاط',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 12),
      PrimaryButton(
        label: 'إرسال طلب التسجيل',
        isLoading: _isLoading,
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          if (!_validateAddress()) return;
          _completeRegistration();
        },
      ),
    ];
  }
}
