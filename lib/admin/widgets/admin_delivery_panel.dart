import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/admin_delivery_user_service.dart';
import 'package:matlobgo/admin/services/admin_gps_service.dart';
import 'package:matlobgo/admin/services/admin_wallet_service.dart';
import 'package:matlobgo/admin/widgets/admin_wallet_audit_dialog.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/user_repository.dart';

class AdminDeliveryPanel extends StatelessWidget {
  const AdminDeliveryPanel({super.key, required this.governorate});

  final Governorate governorate;

  @override
  Widget build(BuildContext context) {
    final repo = UserRepository();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPanelHeader(
          title: 'مندوبي التوصيل',
          subtitle:
              '${governorate.name} — إدارة المندوبين وتفعيلهم وتعيين محافظتهم',
          trailing: FilledButton.icon(
            onPressed: () => _openAgentDialog(context, governorate: governorate),
            icon: const Icon(Icons.person_add, size: 20),
            label: Text(
              'إضافة مندوب',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: repo.watchDeliveryAgents(governorate: governorate.name),
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
              final agents = snapshot.data ?? [];
              if (agents.isEmpty) {
                return AdminEmptyState(
                  icon: Icons.delivery_dining_outlined,
                  message:
                      'لا يوجد مندوبو توصيل.\nاضغط «إضافة مندوب» لإنشاء حساب جديد.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: agents.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _AgentCard(
                  agent: agents[i],
                  repo: repo,
                  onEdit: () => _openAgentDialog(
                    context,
                    governorate: governorate,
                    agent: agents[i],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static Future<void> _openAgentDialog(
    BuildContext context, {
    required Governorate governorate,
    AppUser? agent,
  }) async {
    final nameCtrl = TextEditingController(text: agent?.name ?? '');
    final emailCtrl = TextEditingController(text: agent?.email ?? '');
    final phoneCtrl = TextEditingController(text: agent?.phone ?? '');
    final passCtrl = TextEditingController();
    var isActive = agent?.isActive ?? true;
    var saving = false;
    final repo = UserRepository();
    final createService = AdminDeliveryUserService();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            agent == null ? 'مندوب جديد' : 'تعديل مندوب',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PremiumInputField(
                  controller: nameCtrl,
                  label: 'الاسم',
                ),
                const SizedBox(height: 12),
                AbsorbPointer(
                  absorbing: agent != null,
                  child: PremiumInputField(
                    controller: emailCtrl,
                    label: 'البريد',
                  ),
                ),
                if (agent == null) ...[
                  const SizedBox(height: 12),
                  PremiumInputField(
                    controller: passCtrl,
                    label: 'كلمة المرور',
                    obscureText: true,
                  ),
                ],
                const SizedBox(height: 12),
                PremiumInputField(
                  controller: phoneCtrl,
                  label: 'الهاتف',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('نشط', style: GoogleFonts.cairo()),
                  value: isActive,
                  onChanged: (v) => setLocal(() => isActive = v),
                ),
                if (agent == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'يُنشأ حساب Firebase Auth + Firestore تلقائياً بدور delivery.',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setLocal(() => saving = true);
                      try {
                        if (agent == null) {
                          await createService.createDeliveryUser(
                            email: emailCtrl.text.trim(),
                            password: passCtrl.text,
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            governorate: governorate.name,
                          );
                        } else {
                          await repo.updateUser(
                            agent.copyWith(
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              isActive: isActive,
                              governorate: governorate.name,
                            ),
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(FirestoreErrorMessage.from(e)),
                            ),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setLocal(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      agent == null ? 'إنشاء' : 'حفظ',
                      style: GoogleFonts.cairo(),
                    ),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passCtrl.dispose();
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({
    required this.agent,
    required this.repo,
    required this.onEdit,
  });

  final AppUser agent;
  final UserRepository repo;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (agent.isActive ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.delivery_dining_rounded,
                color: agent.isActive ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agent.name.isEmpty ? 'مندوب' : agent.name,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    agent.phone.isEmpty ? agent.email : agent.phone,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (agent.governorate.isNotEmpty)
                    Text(
                      agent.governorate,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        agent.isOnline ? Icons.circle : Icons.circle_outlined,
                        size: 10,
                        color: agent.isOnline
                            ? AppColors.success
                            : AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        agent.isOnline ? 'متصل' : 'غير متصل',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: agent.isOnline
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (agent.hasLiveLocation) ...[
                        const SizedBox(width: 8),
                        Text(
                          'موقع حي',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (!agent.isGpsTrusted) ...[
                        const SizedBox(width: 8),
                        Text(
                          agent.gpsTrustStatus == 'suspended'
                              ? 'GPS موقوف'
                              : 'GPS مقيد',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (agent.avgDriverRating > 0)
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${agent.avgDriverRating.toStringAsFixed(1)} (${agent.driverRatingCount})',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  if (agent.isOnOfferCooldown) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Cooldown · ${agent.offerCooldownMinutesRemaining} د',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (agent.driverPerformanceScore != null ||
                      agent.acceptRate != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (agent.driverPerformanceScore != null) ...[
                          Icon(
                            Icons.insights_rounded,
                            size: 14,
                            color: _scoreColor(agent.driverPerformanceScore!),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Score ${agent.driverPerformanceScore}',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _scoreColor(agent.driverPerformanceScore!),
                            ),
                          ),
                        ],
                        if (agent.acceptRate != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            'قبول ${(agent.acceptRate!.clamp(0, 1) * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: agent.isActive,
              onChanged: (v) => repo.setDeliveryActive(agent.uid, v),
            ),
            if (!agent.isGpsTrusted)
              IconButton(
                tooltip: 'استعادة GPS',
                onPressed: () => _resetGpsTrust(context, agent.uid),
                icon: const Icon(Icons.gps_off_outlined, color: AppColors.error),
              ),
            IconButton(
              tooltip: 'عرض سجل التدقيق',
              onPressed: () => showWalletAuditTrailDialog(
                context,
                driverId: agent.uid,
                driverName: agent.name,
              ),
              icon: const Icon(
                Icons.history_rounded,
                color: AppColors.textSecondary,
              ),
            ),
            IconButton(
              tooltip: 'تسجيل إيداع',
              onPressed: () => _openWalletSettlement(context, agent),
              icon: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }

  static Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  static Future<void> _resetGpsTrust(BuildContext context, String driverId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'استعادة GPS',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'سيتم رفع إيقاف GPS فوراً، تصفير المخالفات، وإيقاف اتصال المندوب مؤقتاً حتى يعيد التفعيل بنفسه. متابعة؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('استعادة', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await AdminGpsService().resetDriverGpsTrust(driverId: driverId);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت استعادة GPS — شارة الإيقاف تختفي خلال لحظات',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FirestoreErrorMessage.from(e),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  static Future<void> _openWalletSettlement(
    BuildContext context,
    AppUser agent,
  ) async {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            'تسجيل إيداع',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'المستحق الحالي: ${agent.outstandingBalance.toStringAsFixed(2)} ج.م',
                  style: GoogleFonts.cairo(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                PremiumInputField(
                  controller: amountCtrl,
                  label: 'المبلغ',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                PremiumInputField(
                  controller: notesCtrl,
                  label: 'ملاحظات',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final amount = double.tryParse(amountCtrl.text.trim());
                      if (amount == null || amount <= 0) return;
                      setLocal(() => saving = true);
                      try {
                        await AdminWalletService().depositSettlement(
                          driverId: agent.uid,
                          amount: amount,
                          notes: notesCtrl.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      } catch (e) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                              FirestoreErrorMessage.from(e),
                              style: GoogleFonts.cairo(),
                            ),
                          ),
                        );
                      } finally {
                        if (ctx.mounted) setLocal(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('تسجيل', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );

    amountCtrl.dispose();
    notesCtrl.dispose();
  }
}
