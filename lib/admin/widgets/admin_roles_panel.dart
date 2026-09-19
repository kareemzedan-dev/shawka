import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/admin_roles_service.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/egyptian_phone.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/models/admin_staff_role.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/store_repository.dart';
import 'package:matlobgo/repositories/user_repository.dart';

class AdminRolesPanel extends StatelessWidget {
  const AdminRolesPanel({super.key, this.currentUser, this.governorate});

  final AppUser? currentUser;
  final Governorate? governorate;

  @override
  Widget build(BuildContext context) {
    final repo = UserRepository();
    final rolesService = AdminRolesService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPanelHeader(
          title: 'الصلاحيات والأدوار',
          subtitle:
              'عيّن صاحب متجر أو أنشئ حساب مساعد تشغيل (تصنيفات · منتجات · طلبات)',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _openCreateAssistant(
                  context,
                  rolesService: rolesService,
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: Text(
                  'إنشاء مساعد',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openAssignStoreOwner(
                  context,
                  rolesService: rolesService,
                  governorate: governorate,
                ),
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: Text(
                  'تعيين صاحب متجر',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        if (governorate != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text(
              'المحافظة الحالية: ${governorate!.name} — المتاجر المعروضة للربط من هذه المحافظة',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: repo.watchStaffUsers(),
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
              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return const AdminEmptyState(
                  icon: Icons.admin_panel_settings_outlined,
                  message:
                      'لا يوجد موظفون بصلاحية admin.\nأضف role=admin في Firestore.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final user = users[i];
                  final isSelf = user.uid == currentUser?.uid;
                  final isStoreOwner = user.staffRole.isStoreScoped;
                  final isAssistant =
                      user.staffRole == AdminStaffRole.storeAssistant;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0] : 'A',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      _staffIdentity(user),
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 180,
                                child: DropdownButtonFormField<AdminStaffRole>(
                                  key: ValueKey(
                                    '${user.uid}-${user.staffRole.name}',
                                  ),
                                  initialValue: user.staffRole,
                                  decoration: InputDecoration(
                                    labelText: 'الدور',
                                    labelStyle:
                                        GoogleFonts.cairo(fontSize: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  items: [
                                    for (final role in AdminStaffRole.values)
                                      DropdownMenuItem(
                                        value: role,
                                        child: Text(
                                          role.label,
                                          style:
                                              GoogleFonts.cairo(fontSize: 12),
                                        ),
                                      ),
                                  ],
                                  onChanged: isSelf &&
                                          user.staffRole ==
                                              AdminStaffRole.superAdmin
                                      ? null
                                      : (role) async {
                                          if (role == null) return;
                                          await _changeRole(
                                            context,
                                            user: user,
                                            role: role,
                                            rolesService: rolesService,
                                            governorate: governorate,
                                          );
                                        },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (isStoreOwner) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    user.managedStoreIds.isEmpty
                                        ? 'لم يُربط متجر بعد — اضغط «ربط متجر»'
                                        : 'متاجر مرتبطة: ${user.managedStoreIds.length}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: user.managedStoreIds.isEmpty
                                          ? AppColors.error
                                          : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FilledButton.tonalIcon(
                                    onPressed: () => _linkStoresToUser(
                                      context,
                                      user: user,
                                      rolesService: rolesService,
                                      governorate: governorate,
                                    ),
                                    icon: const Icon(Icons.link, size: 18),
                                    label: Text(
                                      'ربط متجر بهذا الحساب',
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (!isSelf) ...[
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _removeStoreOwner(
                                        context,
                                        user: user,
                                        rolesService: rolesService,
                                      ),
                                      icon: const Icon(
                                        Icons.person_remove_outlined,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      label: Text(
                                        'إزالة من أصحاب المتاجر',
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ] else if (isAssistant) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'صلاحيات المساعد: التصنيفات · منتجات المتاجر · متابعة الطلبات',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (!isSelf) ...[
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _removeStoreOwner(
                                        context,
                                        user: user,
                                        rolesService: rolesService,
                                      ),
                                      icon: const Icon(
                                        Icons.person_remove_outlined,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      label: Text(
                                        'إزالة حساب المساعد',
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ] else
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: () => _changeRole(
                                  context,
                                  user: user,
                                  role: AdminStaffRole.storeManager,
                                  rolesService: rolesService,
                                  governorate: governorate,
                                ),
                                icon: const Icon(
                                  Icons.storefront_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  'جعله صاحب متجر + اختيار المتجر',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
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
            },
          ),
        ),
      ],
    );
  }

  String _staffIdentity(AppUser user) {
    if (user.phone.trim().isNotEmpty) {
      return EgyptianPhone.toLocalDisplay(user.phone);
    }
    if (user.email.trim().isNotEmpty) return user.email.trim();
    return user.uid;
  }

  Future<void> _removeStoreOwner(
    BuildContext context, {
    required AppUser user,
    required AdminRolesService rolesService,
  }) async {
    final isAssistant = user.staffRole == AdminStaffRole.storeAssistant;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isAssistant ? 'إزالة حساب المساعد؟' : 'إزالة صاحب المتجر؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        content: Text(
          isAssistant
              ? 'سيتم إزالة صلاحيات لوحة التحكم عن ${user.name} وإرجاع الحساب كعميل عادي.'
              : 'سيتم إزالة ${user.name} من أصحاب المتاجر وإرجاع الحساب كعميل عادي '
                  '(بدون صلاحية لوحة المتجر). بيانات التسجيل تبقى كما هي.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('إزالة', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await rolesService.removeStoreOwner(targetUid: user.uid);
      await AdminSession.instance.record(
        action: AuditAction.roleChange,
        entityType: 'user',
        entityId: user.uid,
        summary: isAssistant
            ? 'إزالة مساعد تشغيل: ${user.name} (${_staffIdentity(user)})'
            : 'إزالة صاحب متجر: ${user.name} (${_staffIdentity(user)})',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAssistant
                  ? 'تم إزالة حساب المساعد'
                  : 'تم إزالة ${user.name} من أصحاب المتاجر',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FirestoreErrorMessage.from(e),
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openCreateAssistant(
    BuildContext context, {
    required AdminRolesService rolesService,
  }) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    var obscure = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                'إنشاء حساب مساعد تشغيل',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'الحساب يدخل لوحة التحكم بالبريد وكلمة المرور، '
                        'ويستطيع إدارة التصنيفات والمنتجات ومتابعة الطلبات.',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'الاسم',
                          labelStyle: GoogleFonts.cairo(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        style: GoogleFonts.cairo(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: 'البريد الإلكتروني (لتسجيل الدخول)',
                          labelStyle: GoogleFonts.cairo(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        style: GoogleFonts.cairo(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d+\s]')),
                          LengthLimitingTextInputFormatter(14),
                        ],
                        decoration: InputDecoration(
                          labelText: 'رقم الموبايل (اختياري)',
                          hintText: '01xxxxxxxxx',
                          labelStyle: GoogleFonts.cairo(),
                          hintStyle: GoogleFonts.cairo(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        style: GoogleFonts.cairo(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passCtrl,
                        obscureText: obscure,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          labelStyle: GoogleFonts.cairo(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setLocal(() => obscure = !obscure),
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        style: GoogleFonts.cairo(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('إلغاء', style: GoogleFonts.cairo()),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('إنشاء الحساب', style: GoogleFonts.cairo()),
                ),
              ],
            );
          },
        );
      },
    );

    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final password = passCtrl.text;
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passCtrl.dispose();

    if (ok != true || !context.mounted) return;
    if (name.length < 2 || !email.contains('@') || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'أدخل اسماً وبريداً صالحاً وكلمة مرور من 6 أحرف على الأقل',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }

    try {
      final result = await rolesService.createStaffUser(
        name: name,
        email: email,
        password: password,
        phone: phone,
        staffRole: AdminStaffRole.storeAssistant,
      );
      await AdminSession.instance.record(
        action: AuditAction.create,
        entityType: 'user',
        entityId: '${result['uid'] ?? email}',
        summary: 'إنشاء مساعد تشغيل: $name ($email)',
        metadata: {'staffRole': 'storeAssistant'},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إنشاء حساب المساعد — يمكنه الدخول بالبريد وكلمة المرور',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FirestoreErrorMessage.from(e),
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _linkStoresToUser(
    BuildContext context, {
    required AppUser user,
    required AdminRolesService rolesService,
    Governorate? governorate,
  }) async {
    if (governorate == null) {
      _needGovernorate(context);
      return;
    }
    final stores = await _pickStores(
      context,
      governorate: governorate,
      initial: user.managedStoreIds,
    );
    if (stores == null || stores.isEmpty) return;
    try {
      await rolesService.setStaffRole(
        targetUid: user.uid,
        staffRole: AdminStaffRole.storeManager,
        managedStoreIds: stores,
      );
      await AdminSession.instance.record(
        action: AuditAction.roleChange,
        entityType: 'user',
        entityId: user.uid,
        summary: 'ربط متاجر بصاحب المتجر ${user.name}',
        metadata: {'managedStoreIds': stores},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم ربط المتجر بنجاح',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FirestoreErrorMessage.from(e),
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _changeRole(
    BuildContext context, {
    required AppUser user,
    required AdminStaffRole role,
    required AdminRolesService rolesService,
    Governorate? governorate,
  }) async {
    try {
      var storeIds = <String>[];
      if (role.isStoreScoped) {
        if (governorate == null) {
          _needGovernorate(context);
          return;
        }
        final picked = await _pickStores(
          context,
          governorate: governorate,
          initial: user.managedStoreIds,
        );
        if (picked == null || picked.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'لازم تختار متجر واحد على الأقل',
                  style: GoogleFonts.cairo(),
                ),
              ),
            );
          }
          return;
        }
        storeIds = picked;
      }
      await rolesService.setStaffRole(
        targetUid: user.uid,
        staffRole: role,
        managedStoreIds: storeIds,
      );
      await AdminSession.instance.record(
        action: AuditAction.roleChange,
        entityType: 'user',
        entityId: user.uid,
        summary: 'تغيير دور ${user.name} إلى ${role.label}',
        metadata: storeIds.isEmpty ? null : {'managedStoreIds': storeIds},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              role.isStoreScoped
                  ? 'تم تعيين ${user.name} صاحب متجر وربط المتجر'
                  : 'تم تغيير الدور إلى ${role.label}',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FirestoreErrorMessage.from(e),
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    }
  }

  void _needGovernorate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'اختَر المحافظة من الشريط أعلى الصفحة أولاً، ثم اربط المتجر',
          style: GoogleFonts.cairo(),
        ),
      ),
    );
  }

  Future<void> _openAssignStoreOwner(
    BuildContext context, {
    required AdminRolesService rolesService,
    Governorate? governorate,
  }) async {
    if (governorate == null) {
      _needGovernorate(context);
      return;
    }

    final phoneController = TextEditingController();
    String? selectedStoreId;
    List<Store> stores = const [];
    try {
      stores = await StoreRepository()
          .watchStoresByGovernorate(governorate: governorate.name)
          .first;
    } catch (_) {}

    if (!context.mounted) return;
    if (stores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا توجد متاجر في ${governorate.name} — أضف متجراً أولاً',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                'تعيين صاحب متجر',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'أدخل رقم موبايل العميل المسجّل واختر المتجر من ${governorate.name}',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d+\s]')),
                        LengthLimitingTextInputFormatter(14),
                      ],
                      decoration: InputDecoration(
                        labelText: 'رقم الموبايل',
                        hintText: '01xxxxxxxxx',
                        labelStyle: GoogleFonts.cairo(),
                        hintStyle: GoogleFonts.cairo(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: GoogleFonts.cairo(),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStoreId,
                      decoration: InputDecoration(
                        labelText: 'المتجر',
                        labelStyle: GoogleFonts.cairo(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: [
                        for (final s in stores)
                          DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              s.name,
                              style: GoogleFonts.cairo(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setLocal(() => selectedStoreId = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('إلغاء', style: GoogleFonts.cairo()),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('تعيين', style: GoogleFonts.cairo()),
                ),
              ],
            );
          },
        );
      },
    );

    final phoneRaw = phoneController.text.trim();
    phoneController.dispose();
    if (ok != true || !context.mounted) return;

    final phoneE164 = EgyptianPhone.toE164(phoneRaw);
    if (phoneE164 == null || selectedStoreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'أدخل رقم موبايل مصري صحيح واختر المتجر',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }

    try {
      final result = await rolesService.assignStoreOwner(
        targetPhone: phoneE164,
        managedStoreIds: [selectedStoreId!],
      );
      final displayPhone = EgyptianPhone.toLocalDisplay(phoneE164);
      await AdminSession.instance.record(
        action: AuditAction.roleChange,
        entityType: 'user',
        entityId: '${result['targetUid'] ?? phoneE164}',
        summary: 'تعيين صاحب متجر لـ $displayPhone',
        metadata: {
          'managedStoreIds': [selectedStoreId],
          'phone': phoneE164,
        },
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تعيين صاحب المتجر بنجاح',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FirestoreErrorMessage.from(e),
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    }
  }

  Future<List<String>?> _pickStores(
    BuildContext context, {
    required Governorate governorate,
    List<String> initial = const [],
  }) async {
    List<Store> stores = const [];
    try {
      stores = await StoreRepository()
          .watchStoresByGovernorate(governorate: governorate.name)
          .first;
    } catch (_) {}
    if (!context.mounted) return null;

    if (stores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا توجد متاجر في ${governorate.name}',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return null;
    }

    final selected = initial.toSet();
    return showDialog<List<String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                'اختر المتجر',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
              ),
              content: SizedBox(
                width: 420,
                height: 360,
                child: ListView.builder(
                  itemCount: stores.length,
                  itemBuilder: (_, i) {
                    final s = stores[i];
                    final checked = selected.contains(s.id);
                    return CheckboxListTile(
                      value: checked,
                      title: Text(
                        s.name,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        s.area.isEmpty ? s.governorate : s.area,
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                      onChanged: (v) {
                        setLocal(() {
                          if (v == true) {
                            selected
                              ..clear()
                              ..add(s.id);
                          } else {
                            selected.remove(s.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('إلغاء', style: GoogleFonts.cairo()),
                ),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(ctx, selected.toList()),
                  child: Text('تأكيد الربط', style: GoogleFonts.cairo()),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
