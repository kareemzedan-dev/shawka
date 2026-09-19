import 'package:flutter/material.dart';
import 'package:matlobgo/core/widgets/app_empty_state.dart';

/// Admin panels — نفس نظام Empty State الموحد (نسخة مدمجة).
class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final lines = message.split('\n');
    final headline = title ?? lines.first;
    final body = title != null
        ? message
        : (lines.length > 1 ? lines.sublist(1).join('\n') : '');

    return AppEmptyState(
      icon: icon,
      title: headline,
      subtitle: body.trim().isEmpty ? null : body.trim(),
      actionLabel: actionLabel,
      onAction: onAction,
      compact: true,
      animate: false,
    );
  }
}
