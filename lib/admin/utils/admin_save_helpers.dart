import 'package:matlobgo/core/utils/firestore_error_message.dart';

/// نتيجة رفع صورة اختياري — null = نجاح.
typedef AdminUploadWarning = String?;

abstract final class AdminSaveHelpers {
  static Future<AdminUploadWarning> tryUpload(
    Future<void> Function() upload, {
    required String label,
  }) async {
    try {
      await upload();
      return null;
    } catch (e) {
      return '$label: ${FirestoreErrorMessage.from(e)}';
    }
  }

  static String partialSaveMessage(List<String> warnings) {
    if (warnings.isEmpty) return '';
    final quotaOnly = warnings.every(
      (w) =>
          FirestoreErrorMessage.isStorageQuotaError(Exception(w)) ||
          w.contains('Storage ممتلئة'),
    );
    if (quotaOnly) {
      return 'تم حفظ البيانات، لكن مساحة التخزين ممتلئة ولم تُرفع الصورة/الصور.';
    }
    return 'تم حفظ البيانات مع تحذيرات:\n${warnings.join('\n')}';
  }
}
