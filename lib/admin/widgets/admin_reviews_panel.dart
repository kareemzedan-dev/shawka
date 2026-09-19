import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/models/admin_permissions.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/admin/utils/admin_format.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/models/admin_staff_role.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/review.dart';
import 'package:matlobgo/repositories/review_repository.dart';

/// إدارة تقييمات العملاء — اعتماد / رفض / حذف / رد صاحب المتجر.
class AdminReviewsPanel extends StatefulWidget {
  const AdminReviewsPanel({super.key});

  @override
  State<AdminReviewsPanel> createState() => _AdminReviewsPanelState();
}

class _AdminReviewsPanelState extends State<AdminReviewsPanel> {
  final _repo = ReviewRepository();
  ReviewStatus? _statusFilter;

  AdminStaffRole get _staffRole =>
      AdminSession.instance.user?.staffRole ?? AdminStaffRole.admin;

  bool get _canReply => AdminPermissions.canManageOrders(_staffRole);
  bool get _canDelete => _staffRole.isSuperOrAdmin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminPanelHeader(
          title: 'تقييمات العملاء',
          subtitle: 'آخر 100 تقييم — اعتماد · رفض · حذف · رد صاحب المتجر',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Wrap(
            spacing: 8,
            children: [
              _filterChip(null, 'الكل'),
              _filterChip(ReviewStatus.pending, 'قيد المراجعة'),
              _filterChip(ReviewStatus.approved, 'معتمد'),
              _filterChip(ReviewStatus.rejected, 'مرفوض'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<Review>>(
            stream: _repo.watchRecent(limit: 100),
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
              final reviews = (snapshot.data ?? [])
                  .where(
                    (r) => _statusFilter == null || r.status == _statusFilter,
                  )
                  .toList();
              if (reviews.isEmpty) {
                return const AdminEmptyState(
                  icon: Icons.reviews_outlined,
                  message: 'لا توجد تقييمات مطابقة.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _ReviewCard(
                  review: reviews[i],
                  canReply: _canReply,
                  canDelete: _canDelete,
                  onSetStatus: _setStatus,
                  onReply: _openReplyDialog,
                  onDelete: _confirmDelete,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(ReviewStatus? status, String label) {
    final selected = _statusFilter == status;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.cairo(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _statusFilter = status),
    );
  }

  Future<void> _setStatus(Review review, ReviewStatus status) async {
    try {
      await _repo.setStatus(review.id, status);
      final actionLabel = switch (status) {
        ReviewStatus.approved => 'اعتماد',
        ReviewStatus.rejected => 'رفض',
        ReviewStatus.pending => 'إرجاع للمراجعة',
      };
      await AdminSession.instance.record(
        action: AuditAction.update,
        entityType: 'review',
        entityId: review.id,
        summary: '$actionLabel تقييم ${review.userName}',
      );
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _openReplyDialog(Review review) async {
    final controller = TextEditingController(text: review.ownerReply ?? '');
    final reply = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'رد صاحب المتجر',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 440,
          child: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            style: GoogleFonts.cairo(),
            decoration: InputDecoration(
              hintText: 'اكتب الرد على التقييم…',
              hintStyle: GoogleFonts.cairo(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('حفظ الرد', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reply == null || reply.isEmpty) return;
    try {
      await _repo.setOwnerReply(review.id, reply);
      await AdminSession.instance.record(
        action: AuditAction.update,
        entityType: 'review',
        entityId: review.id,
        summary: 'رد على تقييم ${review.userName}',
      );
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _confirmDelete(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'حذف التقييم؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'سيتم حذف تقييم ${review.userName} نهائياً وتحديث متوسط التقييم تلقائياً.',
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
            child: Text('حذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.deleteReview(review.id);
      await AdminSession.instance.record(
        action: AuditAction.delete,
        entityType: 'review',
        entityId: review.id,
        summary: 'حذف تقييم ${review.userName}',
      );
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(FirestoreErrorMessage.from(error))),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.canReply,
    required this.canDelete,
    required this.onSetStatus,
    required this.onReply,
    required this.onDelete,
  });

  final Review review;
  final bool canReply;
  final bool canDelete;
  final Future<void> Function(Review, ReviewStatus) onSetStatus;
  final Future<void> Function(Review) onReply;
  final Future<void> Function(Review) onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.userName.isEmpty ? 'عميل' : review.userName,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                  ),
                ),
                _stars(review.rating),
                const SizedBox(width: 12),
                _StatusChip(status: review.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                'متجر: ${review.storeId}',
                if (review.productId.isNotEmpty) 'منتج: ${review.productId}',
                if (review.createdAt != null)
                  AdminFormat.relative(review.createdAt!),
                if (review.helpfulCount > 0) '👍 ${review.helpfulCount}',
              ].join(' · '),
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
            if (review.comment.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment, style: GoogleFonts.cairo(fontSize: 13)),
            ],
            if (review.ownerReply?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'رد المتجر: ${review.ownerReply}',
                  style: GoogleFonts.cairo(fontSize: 12.5),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (review.status != ReviewStatus.approved)
                  TextButton.icon(
                    onPressed: () =>
                        onSetStatus(review, ReviewStatus.approved),
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: AppColors.success,
                    ),
                    label: Text(
                      'اعتماد',
                      style: GoogleFonts.cairo(color: AppColors.success),
                    ),
                  ),
                if (review.status != ReviewStatus.rejected)
                  TextButton.icon(
                    onPressed: () =>
                        onSetStatus(review, ReviewStatus.rejected),
                    icon: const Icon(
                      Icons.block_outlined,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                    label: Text(
                      'رفض',
                      style: GoogleFonts.cairo(color: AppColors.primaryDark),
                    ),
                  ),
                if (canReply)
                  TextButton.icon(
                    onPressed: () => onReply(review),
                    icon: const Icon(Icons.reply_outlined, size: 18),
                    label: Text('رد', style: GoogleFonts.cairo()),
                  ),
                if (canDelete)
                  TextButton.icon(
                    onPressed: () => onDelete(review),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    label: Text(
                      'حذف',
                      style: GoogleFonts.cairo(color: AppColors.error),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: 18,
            color: AppColors.primaryDark,
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ReviewStatus.pending => ('قيد المراجعة', AppColors.primaryDark),
      ReviewStatus.approved => ('معتمد', AppColors.success),
      ReviewStatus.rejected => ('مرفوض', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
