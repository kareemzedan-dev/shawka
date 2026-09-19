import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

/// تصدير CSV — نسخ للحافظة + عرض في حوار.
abstract final class AdminCsvExport {
  static String escape(String value) {
    final v = value.replaceAll('"', '""').replaceAll('\n', ' ');
    if (v.contains(',') || v.contains('"')) return '"$v"';
    return v;
  }

  static String build({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(headers.map(escape).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(escape).join(','));
    }
    return buffer.toString();
  }

  static Future<void> share(
    BuildContext context, {
    required String filename,
    required String csv,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تصدير CSV — $filename',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${csv.split('\n').length - 1} صف · ${(csv.length / 1024).toStringAsFixed(1)} KB',
                style: GoogleFonts.cairo(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csv.length > 8000 ? '${csv.substring(0, 8000)}…' : csv,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إغلاق', style: GoogleFonts.cairo()),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم نسخ CSV إلى الحافظة',
                      style: GoogleFonts.cairo(),
                    ),
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text('نسخ CSV', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
}
