import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/core/widgets/auth_buttons.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/repositories/service_area_analytics_repository.dart';
import 'package:matlobgo/repositories/service_area_waitlist_repository.dart';
import 'package:matlobgo/services/push_notification_service.dart';
import 'package:matlobgo/services/service_area_service.dart';

/// شاشة حظر — المحافظة غير مدعومة حالياً.
class ServiceAreaUnsupportedScreen extends StatefulWidget {
  const ServiceAreaUnsupportedScreen({super.key, required this.onUnblocked});

  final VoidCallback onUnblocked;

  @override
  State<ServiceAreaUnsupportedScreen> createState() =>
      _ServiceAreaUnsupportedScreenState();
}

class _ServiceAreaUnsupportedScreenState
    extends State<ServiceAreaUnsupportedScreen> {
  final _service = ServiceAreaService.instance;
  final _waitlistRepo = ServiceAreaWaitlistRepository();
  final _analytics = ServiceAreaAnalyticsRepository();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _detecting = false;
  bool _waitlistLoading = false;
  bool _waitlistSent = false;
  bool _showWaitlistForm = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String get _governorateLabel =>
      _service.unsupportedName.isNotEmpty ? _service.unsupportedName : 'منطقتك';

  Future<void> _retry() async {
    setState(() => _detecting = true);
    final phase = await _service.retryDetection();
    if (!mounted) return;
    setState(() => _detecting = false);
    if (phase == ServiceAreaPhase.supported ||
        phase == ServiceAreaPhase.browsing) {
      widget.onUnblocked();
    }
  }

  Future<void> _joinWaitlist() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _waitlistLoading = true);
    try {
      final token = await PushNotificationService.instance.currentToken();
      await _waitlistRepo.join(
        name: _nameController.text,
        phone: _phoneController.text,
        governorate: _governorateLabel,
        governorateId: _service.governorate?.id ?? '',
        fcmToken: token ?? '',
      );
      await _analytics.log(
        type: ServiceAreaEventType.waitlistJoin,
        governorate: _governorateLabel,
        governorateId: _service.governorate?.id ?? '',
        supported: false,
      );
      if (mounted) {
        setState(() {
          _waitlistLoading = false;
          _waitlistSent = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _waitlistLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذّر حفظ طلبك — تحقق من الاتصال وحاول مرة أخرى',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: PremiumBackground.scaffoldColor(context),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_off_rounded,
                    color: AppColors.error,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'الخدمة غير متاحة حالياً',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'نعتذر، خدمات ${AppBranding.shortName} غير متوفرة حالياً في:',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.map_rounded,
                        color: AppColors.error.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'محافظة $_governorateLabel',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'نعمل على التوسع قريباً.',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: _detecting ? 'جاري التحقق…' : 'إعادة المحاولة',
                  isLoading: _detecting,
                  onPressed: _detecting ? null : _retry,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      setState(() => _showWaitlistForm = !_showWaitlistForm),
                  child: Text(
                    'إشعاري عند التوفر',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (_showWaitlistForm) ...[
                  const SizedBox(height: 8),
                  if (_waitlistSent)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'تم تسجيلك! سنرسل لك إشعاراً عند توفر الخدمة في $_governorateLabel',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          PremiumInputField(
                            controller: _nameController,
                            label: 'الاسم',
                          ),
                          const SizedBox(height: 12),
                          PremiumInputField(
                            controller: _phoneController,
                            label: 'رقم الهاتف',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'انضم لقائمة الانتظار',
                            isLoading: _waitlistLoading,
                            onPressed: _joinWaitlist,
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
