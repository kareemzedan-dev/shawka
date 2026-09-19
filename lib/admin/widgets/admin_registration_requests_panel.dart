import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/admin_customer_review_service.dart';
import 'package:matlobgo/admin/utils/admin_format.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/egyptian_phone.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/admin/widgets/admin_storage_image.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/user_role.dart';
import 'package:matlobgo/repositories/user_repository.dart';

class AdminRegistrationRequestsPanel extends StatefulWidget {
  const AdminRegistrationRequestsPanel({
    super.key,
    this.embedded = false,
  });

  /// عند التضمين داخل تاب العملاء نخفي الهيدر المكرر.
  final bool embedded;

  @override
  State<AdminRegistrationRequestsPanel> createState() =>
      _AdminRegistrationRequestsPanelState();
}

class _AdminRegistrationRequestsPanelState
    extends State<AdminRegistrationRequestsPanel> {
  final _repo = UserRepository();
  final _review = AdminCustomerReviewService();
  final _busyIds = <String>{};

  Future<void> _approve(AppUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تفعيل الحساب؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'سيتم تفعيل حساب ${EgyptianPhone.toLocalDisplay(user.phone)} والسماح له بالطلب.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('موافقة وتفعيل', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _runReview(user, approve: true);
  }

  Future<void> _reject(AppUser user) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'رفض وحذف الحساب؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'سيتم حذف حساب ${EgyptianPhone.toLocalDisplay(user.phone)} وصور الإثبات نهائياً.',
              style: GoogleFonts.cairo(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                labelStyle: GoogleFonts.cairo(),
              ),
              style: GoogleFonts.cairo(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('رفض وحذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    final note = noteCtrl.text.trim();
    noteCtrl.dispose();
    if (ok != true) return;
    await _runReview(user, approve: false, note: note);
  }

  Future<void> _runReview(
    AppUser user, {
    required bool approve,
    String note = '',
  }) async {
    setState(() => _busyIds.add(user.uid));
    try {
      if (approve) {
        await _review.approve(user.uid, note: note);
      } else {
        await _review.reject(user.uid, note: note);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve ? 'تم تفعيل الحساب' : 'تم رفض الطلب وحذف الحساب',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirestoreErrorMessage.from(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(user.uid));
    }
  }

  void _openProof(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        final size = MediaQuery.sizeOf(ctx);
        final maxW = size.width * 0.92;
        final maxH = size.height * 0.9;
        return Dialog(
          backgroundColor: const Color(0xFF111827),
          insetPadding: const EdgeInsets.all(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: maxW,
            height: maxH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 6,
                  child: SizedBox(
                    width: maxW,
                    height: maxH,
                    child: AdminStorageImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      fallback: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'تعذر تحميل صورة الإثبات',
                              style: GoogleFonts.cairo(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'إغلاق',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
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

  Widget _proofThumb(String url) {
    return AdminStorageImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fallback: ColoredBox(
        color: AppColors.surfaceMuted,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textHint,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embedded)
          const AdminPanelHeader(
            title: 'طلبات تسجيل العملاء',
            subtitle:
                'مراجعة حسابات العملاء الجدد مع صورة إثبات المكان — موافقة أو رفض وحذف',
          ),
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: _repo.watchUsersByRole(UserRole.customer),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
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

              final pending = (snapshot.data ?? [])
                  .where((u) => u.isCustomerPendingApproval)
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (pending.isEmpty) {
                return const AdminEmptyState(
                  icon: Icons.mark_email_read_outlined,
                  message: 'لا توجد طلبات تسجيل بانتظار المراجعة.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                itemCount: pending.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = pending[index];
                  final busy = _busyIds.contains(user.uid);
                  final proof = user.proofImageUrl.isNotEmpty
                      ? user.proofImageUrl
                      : user.proofImageThumbUrl;
                  final thumb = user.proofImageThumbUrl.isNotEmpty
                      ? user.proofImageThumbUrl
                      : proof;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 96,
                                  height: 96,
                                  child: proof.isEmpty
                                      ? ColoredBox(
                                          color: AppColors.surfaceMuted,
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            color: AppColors.textHint,
                                          ),
                                        )
                                      : InkWell(
                                          onTap: () => _openProof(proof),
                                          child: _proofThumb(thumb),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.activityTypeName.isNotEmpty
                                          ? user.activityTypeName
                                          : (user.name.isNotEmpty
                                              ? user.name
                                              : 'عميل جديد'),
                                      style: GoogleFonts.cairo(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      EgyptianPhone.toLocalDisplay(user.phone),
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'تاريخ الطلب: ${AdminFormat.dateTime(user.createdAt)}',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (user.name.isNotEmpty &&
                                        user.name != user.activityTypeName)
                                      Text(
                                        'الاسم: ${user.name}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    if (user.address.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'العنوان: ${user.address.trim()}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (proof.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => _openProof(proof),
                              icon: const Icon(Icons.zoom_in_rounded, size: 18),
                              label: Text(
                                'عرض صورة الإثبات بالحجم الكامل',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: busy ? null : () => _approve(user),
                                  icon: busy
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.check_rounded),
                                  label: Text(
                                    'موافقة',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: busy ? null : () => _reject(user),
                                  icon: const Icon(
                                    Icons.delete_forever_rounded,
                                    color: AppColors.error,
                                  ),
                                  label: Text(
                                    'رفض وحذف',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
}
