import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

/// قائمة قابلة لإعادة الترتيب بالسحب — تحدّث sortOrder تلقائياً.
class AdminReorderableList extends StatelessWidget {
  const AdminReorderableList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    this.padding,
    this.header,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Future<void> Function(int oldIndex, int newIndex) onReorder;
  final EdgeInsets? padding;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?header,
        Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Row(
            children: [
              Icon(Icons.drag_handle_rounded,
                  size: 16, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text(
                'اسحب ⋮⋮ لإعادة الترتيب',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: padding ?? const EdgeInsets.fromLTRB(24, 0, 24, 24),
            buildDefaultDragHandles: false,
            itemCount: itemCount,
            onReorderItem: onReorder,
            itemBuilder: (context, index) {
              return Material(
                key: ValueKey('reorder_$index'),
                color: Colors.transparent,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20, left: 4, right: 8),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                    Expanded(child: itemBuilder(context, index)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
