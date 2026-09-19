import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/admin/utils/audit_diff.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/bottom_nav_config.dart';
import 'package:matlobgo/models/checkout_payment_method.dart';
import 'package:matlobgo/repositories/app_settings_repository.dart';
import 'package:matlobgo/config/branding/generated/branding_values.g.dart';

class AdminSettingsPanel extends StatefulWidget {
  const AdminSettingsPanel({super.key});

  @override
  State<AdminSettingsPanel> createState() => _AdminSettingsPanelState();
}

class _AdminSettingsPanelState extends State<AdminSettingsPanel> {
  final _repo = AppSettingsRepository();
  final _formKey = GlobalKey<FormState>();
  final _supportPhone = TextEditingController();
  final _welcomeMessage = TextEditingController();
  final _defaultDeliveryFee = TextEditingController();
  final _minOrderAmount = TextEditingController();
  final _freeDeliveryThreshold = TextEditingController();
  final _serviceFeeFixed = TextEditingController();
  final _serviceFeePercent = TextEditingController();
  final _taxPercent = TextEditingController();
  List<CheckoutPaymentMethod> _paymentMethods = [];
  bool _enableGuestCheckout = true;
  bool _suggestionsEnabled = true;
  bool _freeDeliveryProgressEnabled = true;
  bool _bottomNavBadgeEnabled = true;
  bool _favoritesTabVisible = true;
  String _badgeStyle = 'count';
  AppSettings? _before;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _supportPhone.dispose();
    _welcomeMessage.dispose();
    _defaultDeliveryFee.dispose();
    _minOrderAmount.dispose();
    _freeDeliveryThreshold.dispose();
    _serviceFeeFixed.dispose();
    _serviceFeePercent.dispose();
    _taxPercent.dispose();
    super.dispose();
  }

  void _apply(AppSettings s) {
    _before = s;
    _supportPhone.text = s.supportPhone;
    _welcomeMessage.text = s.welcomeMessage;
    _defaultDeliveryFee.text = s.defaultDeliveryFee.toString();
    _minOrderAmount.text = s.minOrderAmount.toString();
    _freeDeliveryThreshold.text = s.freeDeliveryThreshold.toString();
    _serviceFeeFixed.text = s.checkoutServiceFeeFixed.toString();
    _serviceFeePercent.text = s.checkoutServiceFeePercent.toString();
    _taxPercent.text = s.checkoutTaxPercent.toString();
    _paymentMethods = [...s.checkoutPaymentMethods]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _enableGuestCheckout = s.enableGuestCheckout;
    _suggestionsEnabled = s.cartUi.suggestionsEnabled;
    _freeDeliveryProgressEnabled = s.cartUi.freeDeliveryProgressEnabled;
    _bottomNavBadgeEnabled = s.bottomNav.badgeEnabled;
    _badgeStyle = s.bottomNav.badgeStyle;
    _favoritesTabVisible = s.bottomNav.tabs
        .firstWhere(
          (tab) => tab.id == 'favorites',
          orElse: () => const BottomNavTabConfig(id: 'favorites'),
        )
        .visible;
    _loaded = true;
  }

  AppSettings _build() {
    final prev = _before ?? const AppSettings();
    final bottomTabs = BottomNavConfig.defaults.map((tab) {
      if (tab.id == 'favorites') {
        return tab.copyWith(visible: _favoritesTabVisible);
      }
      return tab.copyWith(showBadge: tab.id == 'cart');
    }).toList();
    return prev.copyWith(
      supportPhone: _supportPhone.text.trim(),
      welcomeMessage: _welcomeMessage.text.trim(),
      defaultDeliveryFee:
          double.tryParse(_defaultDeliveryFee.text.trim()) ?? 15,
      minOrderAmount: double.tryParse(_minOrderAmount.text.trim()) ?? 50,
      enableGuestCheckout: _enableGuestCheckout,
      freeDeliveryThreshold:
          double.tryParse(_freeDeliveryThreshold.text.trim()) ?? 200,
      checkoutServiceFeeFixed:
          double.tryParse(_serviceFeeFixed.text.trim()) ?? 0,
      checkoutServiceFeePercent:
          double.tryParse(_serviceFeePercent.text.trim()) ?? 0,
      checkoutTaxPercent: double.tryParse(_taxPercent.text.trim()) ?? 0,
      enabledPaymentMethods: _paymentMethods
          .where((method) => method.isActive)
          .map((method) => method.id)
          .toList(),
      checkoutPaymentMethods: _paymentMethods,
      cartUi: prev.cartUi.copyWith(
        suggestionsEnabled: _suggestionsEnabled,
        freeDeliveryProgressEnabled: _freeDeliveryProgressEnabled,
      ),
      bottomNav: BottomNavConfig(
        badgeEnabled: _bottomNavBadgeEnabled,
        badgeStyle: _badgeStyle,
        tabs: bottomTabs,
      ),
    );
  }

  Future<void> _editPaymentMethod({CheckoutPaymentMethod? existing}) async {
    final id = TextEditingController(text: existing?.id ?? '');
    final name = TextEditingController(text: existing?.name ?? '');
    final description = TextEditingController(
      text: existing?.description ?? '',
    );
    final logoUrl = TextEditingController(text: existing?.logoUrl ?? '');
    final feeFixed = TextEditingController(
      text: (existing?.feeFixed ?? 0).toString(),
    );
    final feePercent = TextEditingController(
      text: (existing?.feePercent ?? 0).toString(),
    );
    final minOrder = TextEditingController(
      text: (existing?.minOrderAmount ?? 0).toString(),
    );
    final maxOrder = TextEditingController(
      text: (existing?.maxOrderAmount ?? 0).toString(),
    );
    final governorates = TextEditingController(
      text: existing?.governorates.join(', ') ?? '',
    );
    final storeIds = TextEditingController(
      text: existing?.storeIds.join(', ') ?? '',
    );
    final categoryIds = TextEditingController(
      text: existing?.categoryIds.join(', ') ?? '',
    );
    final reason = TextEditingController(
      text: existing?.unavailableReason ?? '',
    );
    var isActive = existing?.isActive ?? true;

    List<String> csv(TextEditingController controller) => controller.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'إضافة وسيلة دفع' : 'تعديل وسيلة الدفع',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PremiumInputField(
                    controller: id,
                    label: 'المعرّف (cash / card / instapay...)',
                  ),
                  const SizedBox(height: 8),
                  PremiumInputField(controller: name, label: 'الاسم'),
                  const SizedBox(height: 8),
                  PremiumInputField(controller: description, label: 'الوصف'),
                  const SizedBox(height: 8),
                  PremiumInputField(controller: logoUrl, label: 'رابط الشعار'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: PremiumInputField(
                          controller: feeFixed,
                          label: 'رسوم ثابتة',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PremiumInputField(
                          controller: feePercent,
                          label: 'رسوم %',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: PremiumInputField(
                          controller: minOrder,
                          label: 'أقل قيمة طلب',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PremiumInputField(
                          controller: maxOrder,
                          label: 'أعلى قيمة (0 = بلا حد)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PremiumInputField(
                    controller: governorates,
                    label: 'المحافظات (مفصولة بفاصلة)',
                  ),
                  const SizedBox(height: 8),
                  PremiumInputField(
                    controller: storeIds,
                    label: 'معرّفات المتاجر (مفصولة بفاصلة)',
                  ),
                  const SizedBox(height: 8),
                  PremiumInputField(
                    controller: categoryIds,
                    label: 'معرّفات التصنيفات (مفصولة بفاصلة)',
                  ),
                  const SizedBox(height: 8),
                  PremiumInputField(
                    controller: reason,
                    label: 'سبب عدم الإتاحة',
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('مفعّلة', style: GoogleFonts.cairo()),
                    value: isActive,
                    onChanged: (value) =>
                        setDialogState(() => isActive = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            FilledButton(
              onPressed: () {
                final methodId = id.text.trim();
                if (methodId.isEmpty || name.text.trim().isEmpty) return;
                final next = CheckoutPaymentMethod(
                  id: methodId,
                  name: name.text.trim(),
                  description: description.text.trim(),
                  logoUrl: logoUrl.text.trim(),
                  isActive: isActive,
                  sortOrder: existing?.sortOrder ?? _paymentMethods.length,
                  feeFixed: double.tryParse(feeFixed.text.trim()) ?? 0,
                  feePercent: double.tryParse(feePercent.text.trim()) ?? 0,
                  governorates: csv(governorates),
                  storeIds: csv(storeIds),
                  categoryIds: csv(categoryIds),
                  minOrderAmount: double.tryParse(minOrder.text.trim()) ?? 0,
                  maxOrderAmount: double.tryParse(maxOrder.text.trim()) ?? 0,
                  unavailableReason: reason.text.trim(),
                );
                setState(() {
                  if (existing == null) {
                    _paymentMethods.add(next);
                  } else {
                    final index = _paymentMethods.indexWhere(
                      (method) => method.id == existing.id,
                    );
                    if (index >= 0) _paymentMethods[index] = next;
                  }
                });
                Navigator.pop(dialogContext);
              },
              child: Text('حفظ', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );

    for (final controller in [
      id,
      name,
      description,
      logoUrl,
      feeFixed,
      feePercent,
      minOrder,
      maxOrder,
      governorates,
      storeIds,
      categoryIds,
      reason,
    ]) {
      controller.dispose();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final next = _build();
      await _repo.save(next);
      await AdminSession.instance.recordWithDiff(
        action: AuditAction.update,
        entityType: 'app_settings',
        entityId: AppSettings.documentId,
        summary: 'تحديث إعدادات التطبيق',
        before: _before != null
            ? AuditDiff.snapshot(_before!.toFirestore())
            : null,
        after: AuditDiff.snapshot(next.toFirestore()),
      );
      _before = next;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(FirestoreErrorMessage.from(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppSettings>(
      stream: _repo.watch(),
      builder: (context, snapshot) {
        if (snapshot.hasData && !_loaded) {
          _apply(snapshot.data!);
        }

        if (snapshot.connectionState == ConnectionState.waiting && !_loaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AdminPanelHeader(
                title: 'إعدادات التطبيق',
                subtitle:
                    'إعدادات عامة تؤثر على تجربة العملاء في ${BrandingValues.appName}',
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionTitle('عام'),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'السماح بالدخول كزائر',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'التصفح والسلة فقط — إتمام الطلب يحتاج حساباً حقيقياً دائماً',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            value: _enableGuestCheckout,
                            onChanged: (v) =>
                                setState(() => _enableGuestCheckout = v),
                          ),
                          PremiumInputField(
                            controller: _welcomeMessage,
                            label: 'رسالة الترحيب',
                          ),
                          PremiumInputField(
                            controller: _supportPhone,
                            label: 'هاتف الدعم',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),
                          _SectionTitle('التوصيل والطلبات'),
                          PremiumInputField(
                            controller: _defaultDeliveryFee,
                            label: 'رسوم التوصيل الافتراضية (ج.م)',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          PremiumInputField(
                            controller: _minOrderAmount,
                            label: 'الحد الأدنى للطلب (ج.م)',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          PremiumInputField(
                            controller: _freeDeliveryThreshold,
                            label: 'توصيل مجاني فوق (ج.م)',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          _SectionTitle('السلة والتنقل'),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'إظهار مقترحات السلة',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            value: _suggestionsEnabled,
                            onChanged: (v) =>
                                setState(() => _suggestionsEnabled = v),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'بطاقة تقدّم التوصيل المجاني',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            value: _freeDeliveryProgressEnabled,
                            onChanged: (v) => setState(
                              () => _freeDeliveryProgressEnabled = v,
                            ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'إظهار شارة عدد السلة في التنقل',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            value: _bottomNavBadgeEnabled,
                            onChanged: (v) =>
                                setState(() => _bottomNavBadgeEnabled = v),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'شكل الشارة',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'count',
                                label: Text('رقم'),
                              ),
                              ButtonSegment(
                                value: 'dot',
                                label: Text('نقطة'),
                              ),
                            ],
                            selected: {_badgeStyle},
                            onSelectionChanged: (value) {
                              setState(() => _badgeStyle = value.first);
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'إظهار تبويب المفضلة',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'التبويبات الأساسية (الرئيسية/السلة/طلباتي/حسابي) تبقى ظاهرة دائماً',
                              style: GoogleFonts.cairo(fontSize: 12),
                            ),
                            value: _favoritesTabVisible,
                            onChanged: (v) =>
                                setState(() => _favoritesTabVisible = v),
                          ),
                          const SizedBox(height: 20),
                          _SectionTitle('رسوم Checkout الخادمية'),
                          Row(
                            children: [
                              Expanded(
                                child: PremiumInputField(
                                  controller: _serviceFeeFixed,
                                  label: 'رسوم خدمة ثابتة',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PremiumInputField(
                                  controller: _serviceFeePercent,
                                  label: 'رسوم خدمة %',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PremiumInputField(
                                  controller: _taxPercent,
                                  label: 'ضرائب %',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(
                                child: _SectionTitle('وسائل الدفع'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _editPaymentMethod,
                                icon: const Icon(Icons.add_rounded),
                                label: Text(
                                  'إضافة وسيلة',
                                  style: GoogleFonts.cairo(),
                                ),
                              ),
                            ],
                          ),
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _paymentMethods.length,
                            onReorderItem: (oldIndex, newIndex) {
                              setState(() {
                                final item = _paymentMethods.removeAt(oldIndex);
                                _paymentMethods.insert(newIndex, item);
                                _paymentMethods = _paymentMethods
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => entry.value.copyWith(
                                        sortOrder: entry.key,
                                      ),
                                    )
                                    .toList();
                              });
                            },
                            itemBuilder: (context, index) {
                              final method = _paymentMethods[index];
                              return Card(
                                key: ValueKey(method.id),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.drag_handle_rounded,
                                  ),
                                  title: Text(
                                    method.name,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${method.id} · ${method.description}',
                                    style: GoogleFonts.cairo(fontSize: 12),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: method.isActive,
                                        onChanged: (value) => setState(() {
                                          _paymentMethods[index] = method
                                              .copyWith(isActive: value);
                                        }),
                                      ),
                                      IconButton(
                                        onPressed: () => _editPaymentMethod(
                                          existing: method,
                                        ),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        onPressed: () => setState(
                                          () => _paymentMethods.removeAt(index),
                                        ),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                          FilledButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'حفظ الإعدادات',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
    );
  }
}
