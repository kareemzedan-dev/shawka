import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/widgets/auth_layout.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/services/auth_service.dart';
import 'package:matlobgo/services/theme_service.dart';

Future<void> openEditProfileScreen(
  BuildContext context, {
  required AppUser user,
  required AuthService authService,
  required VoidCallback onSaved,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          EditProfileScreen(
        user: user,
        authService: authService,
        onSaved: onSaved,
      ),
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    ),
  );
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.user,
    required this.authService,
    required this.onSaved,
  });

  final AppUser user;
  final AuthService authService;
  final VoidCallback onSaved;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late String _governorate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _governorate = widget.user.governorate.isNotEmpty
        ? widget.user.governorate
        : EgyptGovernorates.defaultGovernorate.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      await widget.authService.updateProfile(
        uid: widget.user.uid,
        name: _nameController.text,
        phone: _phoneController.text,
        governorate: _governorate,
      );
      if (!mounted) return;
      widget.onSaved();
      showAuthMessage(context, 'تم حفظ التغييرات');
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showAuthMessage(context, 'تعذّر حفظ التغييرات', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final palette = context.palette;
        final govOptions = EgyptGovernorates.available;

        return Scaffold(
          backgroundColor: PremiumBackground.scaffoldColor(context),
          appBar: AppBar(
            backgroundColor: PremiumBackground.scaffoldColor(context),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'تعديل الملف الشخصي',
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: palette.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  'حدّث بياناتك الشخصية',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                PremiumInputField(
                  label: 'الاسم الكامل',
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'أدخل اسماً صحيحاً';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PremiumInputField(
                  label: 'رقم الهاتف',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return null;
                    if (phone.length < 10) return 'رقم الهاتف غير صحيح';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'المحافظة',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: HomeTheme.borderMd,
                    border: Border.all(color: palette.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: govOptions.any((g) => g.name == _governorate)
                          ? _governorate
                          : govOptions.first.name,
                      isExpanded: true,
                      icon: Icon(Icons.expand_more_rounded,
                          color: palette.textHint),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                      items: [
                        for (final gov in govOptions)
                          DropdownMenuItem(
                            value: gov.name,
                            child: Text(gov.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _governorate = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: HomeTheme.borderMd,
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'حفظ التغييرات',
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
