import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/admin/utils/admin_format.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/models/promotion.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/promotion_repository.dart';
import 'package:matlobgo/repositories/store_repository.dart';

class AdminPromotionsPanel extends StatelessWidget {
  const AdminPromotionsPanel({
    super.key,
    required this.governorate,
    this.actor,
  });

  final Governorate governorate;
  final dynamic actor;

  @override
  Widget build(BuildContext context) {
    final repo = PromotionRepository();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPanelHeader(
          title: 'العروض والخصومات',
          subtitle:
              '${governorate.name} — أكواد خصم · توصيل مجاني · فترات محددة',
          trailing: FilledButton.icon(
            onPressed: () => _openForm(context, repo),
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              'عرض جديد',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Promotion>>(
            stream: repo.watchByGovernorate(governorate.name),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    FirestoreErrorMessage.from(snapshot.error!),
                    style: GoogleFonts.cairo(color: AppColors.error),
                  ),
                );
              }
              final promos = snapshot.data ?? [];
              if (promos.isEmpty) {
                return const AdminEmptyState(
                  icon: Icons.local_offer_outlined,
                  message: 'لا توجد عروض — أضف أول كود خصم.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: promos.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final promo = promos[i];
                  final storeLine = promo.storeId.isNotEmpty
                      ? ' · ${promo.storeName.isNotEmpty ? promo.storeName : promo.storeId}'
                      : '';
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: promo.isValidNow
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.textHint.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.local_offer_rounded,
                          color: promo.isValidNow
                              ? AppColors.success
                              : AppColors.textHint,
                        ),
                      ),
                      title: Text(
                        '${promo.code} — ${promo.title}',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${promo.type.label}$storeLine · ${AdminFormat.dateTime(promo.startsAt)} → ${AdminFormat.dateTime(promo.endsAt)}',
                        style: GoogleFonts.cairo(fontSize: 11.5),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: promo.isActive,
                            onChanged: (v) async {
                              await repo.setActive(promo.id, v);
                              await AdminSession.instance.record(
                                action: AuditAction.update,
                                entityType: 'promotion',
                                entityId: promo.id,
                                summary:
                                    '${v ? 'تفعيل' : 'إيقاف'} عرض ${promo.code}',
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                _openForm(context, repo, existing: promo),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                            onPressed: () async {
                              await repo.delete(promo.id);
                              await AdminSession.instance.record(
                                action: AuditAction.delete,
                                entityType: 'promotion',
                                entityId: promo.id,
                                summary: 'حذف عرض ${promo.code}',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openForm(
    BuildContext context,
    PromotionRepository repo, {
    Promotion? existing,
  }) async {
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final valueCtrl = TextEditingController(
      text: existing?.value.toString() ?? '10',
    );
    final minOrderCtrl = TextEditingController(
      text: (existing?.minOrderAmount ?? 0).toString(),
    );
    final maxDiscountCtrl = TextEditingController(
      text: (existing?.maxDiscount ?? 0).toString(),
    );
    final usageLimitCtrl = TextEditingController(
      text: (existing?.usageLimit ?? 0).toString(),
    );
    final perUserLimitCtrl = TextEditingController(
      text: (existing?.perUserLimit ?? 0).toString(),
    );
    final categoryIdsCtrl = TextEditingController(
      text: existing?.categoryIds.join(', ') ?? '',
    );
    final productIdsCtrl = TextEditingController(
      text: existing?.productIds.join(', ') ?? '',
    );
    final storeRepo = StoreRepository();
    var type = existing?.type ?? PromotionType.percent;
    var starts = existing?.startsAt ?? DateTime.now();
    var ends = existing?.endsAt ?? DateTime.now().add(const Duration(days: 30));
    String? storeId = existing?.storeId.isNotEmpty == true
        ? existing!.storeId
        : null;
    String storeName = existing?.storeName ?? '';

    Future<void> pickDateTime(
      BuildContext ctx,
      void Function(void Function()) setLocal, {
      required bool isStart,
    }) async {
      final initial = isStart ? starts : ends;
      final date = await showDatePicker(
        context: ctx,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
        helpText: isStart ? 'تاريخ البداية' : 'تاريخ النهاية',
      );
      if (date == null || !ctx.mounted) return;
      final time = await showTimePicker(
        context: ctx,
        initialTime: TimeOfDay.fromDateTime(initial),
        helpText: isStart ? 'وقت البداية' : 'وقت النهاية',
      );
      if (time == null) return;
      final combined = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      setLocal(() {
        if (isStart) {
          starts = combined;
        } else {
          ends = combined;
        }
      });
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(
              existing == null ? 'عرض جديد' : 'تعديل العرض',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PremiumInputField(controller: codeCtrl, label: 'كود الخصم'),
                    const SizedBox(height: 8),
                    PremiumInputField(controller: titleCtrl, label: 'العنوان'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<PromotionType>(
                      initialValue: type,
                      decoration: InputDecoration(
                        labelText: 'نوع العرض',
                        labelStyle: GoogleFonts.cairo(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        for (final t in PromotionType.values)
                          DropdownMenuItem(value: t, child: Text(t.label)),
                      ],
                      onChanged: (v) {
                        if (v != null) setLocal(() => type = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    PremiumInputField(
                      controller: valueCtrl,
                      keyboardType: TextInputType.number,
                      label: type == PromotionType.percent
                          ? 'النسبة %'
                          : 'المبلغ ج.م',
                    ),
                    const SizedBox(height: 8),
                    PremiumInputField(
                      controller: minOrderCtrl,
                      label: 'الحد الأدنى للطلب (ج.م)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    PremiumInputField(
                      controller: maxDiscountCtrl,
                      label: 'الحد الأقصى للخصم (0 = بلا حد)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: PremiumInputField(
                            controller: usageLimitCtrl,
                            label: 'حد الاستخدام الكلي',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PremiumInputField(
                            controller: perUserLimitCtrl,
                            label: 'حد الاستخدام للمستخدم',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PremiumInputField(
                      controller: categoryIdsCtrl,
                      label: 'معرّفات التصنيفات (مفصولة بفاصلة)',
                    ),
                    const SizedBox(height: 8),
                    PremiumInputField(
                      controller: productIdsCtrl,
                      label: 'معرّفات المنتجات (مفصولة بفاصلة)',
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<Store>>(
                      stream: storeRepo.watchStoresByGovernorate(
                        governorate: governorate.name,
                      ),
                      builder: (context, snap) {
                        final stores = snap.data ?? [];
                        return DropdownButtonFormField<String?>(
                          initialValue: storeId,
                          decoration: InputDecoration(
                            labelText: 'المتجر (فارغ = كل المتاجر)',
                            labelStyle: GoogleFonts.cairo(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'كل المتاجر',
                                style: GoogleFonts.cairo(),
                              ),
                            ),
                            for (final s in stores)
                              DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name, style: GoogleFonts.cairo()),
                              ),
                          ],
                          onChanged: (v) {
                            setLocal(() {
                              storeId = v;
                              storeName = v == null
                                  ? ''
                                  : stores.firstWhere((s) => s.id == v).name;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'يبدأ',
                        style: GoogleFonts.cairo(fontSize: 13),
                      ),
                      subtitle: Text(
                        AdminFormat.dateTime(starts),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                      ),
                      trailing: TextButton(
                        onPressed: () =>
                            pickDateTime(ctx, setLocal, isStart: true),
                        child: Text('تغيير', style: GoogleFonts.cairo()),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'ينتهي',
                        style: GoogleFonts.cairo(fontSize: 13),
                      ),
                      subtitle: Text(
                        AdminFormat.dateTime(ends),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                      ),
                      trailing: TextButton(
                        onPressed: () =>
                            pickDateTime(ctx, setLocal, isStart: false),
                        child: Text('تغيير', style: GoogleFonts.cairo()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
              FilledButton(
                onPressed: () async {
                  final promo = Promotion(
                    id: existing?.id ?? '',
                    code: codeCtrl.text.trim().toUpperCase(),
                    title: titleCtrl.text.trim(),
                    type: type,
                    value: double.tryParse(valueCtrl.text.trim()) ?? 0,
                    governorate: governorate.name,
                    storeId: storeId ?? '',
                    storeName: storeName,
                    isActive: existing?.isActive ?? true,
                    startsAt: starts,
                    endsAt: ends,
                    sortOrder: existing?.sortOrder ?? 0,
                    minOrderAmount:
                        double.tryParse(minOrderCtrl.text.trim()) ?? 0,
                    maxDiscount:
                        double.tryParse(maxDiscountCtrl.text.trim()) ?? 0,
                    usageLimit: int.tryParse(usageLimitCtrl.text.trim()) ?? 0,
                    usageCount: existing?.usageCount ?? 0,
                    perUserLimit:
                        int.tryParse(perUserLimitCtrl.text.trim()) ?? 0,
                    governorates: [governorate.name],
                    storeIds: storeId == null ? const [] : [storeId!],
                    categoryIds: categoryIdsCtrl.text
                        .split(',')
                        .map((value) => value.trim())
                        .where((value) => value.isNotEmpty)
                        .toList(),
                    productIds: productIdsCtrl.text
                        .split(',')
                        .map((value) => value.trim())
                        .where((value) => value.isNotEmpty)
                        .toList(),
                  );
                  if (existing == null) {
                    final id = await repo.create(promo);
                    await AdminSession.instance.record(
                      action: AuditAction.create,
                      entityType: 'promotion',
                      entityId: id,
                      summary: 'إضافة عرض ${promo.code}',
                    );
                  } else {
                    await repo.update(promo);
                    await AdminSession.instance.record(
                      action: AuditAction.update,
                      entityType: 'promotion',
                      entityId: promo.id,
                      summary: 'تعديل عرض ${promo.code}',
                    );
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text('حفظ', style: GoogleFonts.cairo()),
              ),
            ],
          );
        },
      ),
    );

    codeCtrl.dispose();
    titleCtrl.dispose();
    valueCtrl.dispose();
    minOrderCtrl.dispose();
    maxDiscountCtrl.dispose();
    usageLimitCtrl.dispose();
    perUserLimitCtrl.dispose();
    categoryIdsCtrl.dispose();
    productIdsCtrl.dispose();
  }
}
