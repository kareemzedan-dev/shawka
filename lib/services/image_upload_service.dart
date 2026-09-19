import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:matlobgo/core/constants/storage_paths.dart';
import 'package:matlobgo/core/utils/image_compressor.dart';
import 'package:matlobgo/core/utils/promo_banner_debug.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/models/image_upload_result.dart';
import 'package:matlobgo/services/image_archive_service.dart';

class ImageUploadService {
  ImageUploadService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<ImageUploadResult> uploadStoreLogo({
    required String storeId,
    required Uint8List bytes,
  }) {
    return _uploadPair(
      fullPath: StoragePaths.storeLogo(storeId),
      thumbPath: StoragePaths.storeLogoThumb(storeId),
      bytes: bytes,
      kind: ImageUploadKind.storeLogo,
    );
  }

  Future<ImageUploadResult> uploadStoreCover({
    required String storeId,
    required Uint8List bytes,
  }) {
    return _uploadPair(
      fullPath: StoragePaths.storeCover(storeId),
      thumbPath: StoragePaths.storeCoverThumb(storeId),
      bytes: bytes,
      kind: ImageUploadKind.storeCover,
    );
  }

  Future<ImageUploadResult> uploadProductImage({
    required String storeId,
    required String productId,
    required Uint8List bytes,
  }) {
    return _uploadPair(
      fullPath: StoragePaths.productImage(storeId, productId),
      thumbPath: StoragePaths.productImageThumb(storeId, productId),
      bytes: bytes,
      kind: ImageUploadKind.product,
    );
  }

  Future<ImageUploadResult> uploadPromoBannerImage({
    required String bannerId,
    required Uint8List bytes,
  }) {
    PromoBannerDebug.log(
      'Storage.upload bannerId=$bannerId '
      'path=${StoragePaths.promoBanner(bannerId)} '
      'bytes=${bytes.length} bucket=${_storage.bucket}',
    );
    return _uploadPair(
      fullPath: StoragePaths.promoBanner(bannerId),
      thumbPath: StoragePaths.promoBannerThumb(bannerId),
      bytes: bytes,
      kind: ImageUploadKind.promoBanner,
    );
  }

  Future<ImageUploadResult> uploadStoreCategoryImage({
    required String governorateKey,
    required String categoryId,
    required Uint8List bytes,
  }) {
    return _uploadPair(
      fullPath: StoragePaths.storeCategory(governorateKey, categoryId),
      thumbPath: StoragePaths.storeCategoryThumb(governorateKey, categoryId),
      bytes: bytes,
      kind: ImageUploadKind.storeCategory,
    );
  }

  Future<ImageUploadResult> uploadCustomerProof({
    required String userId,
    required Uint8List bytes,
  }) {
    return _uploadPair(
      fullPath: StoragePaths.customerProof(userId),
      thumbPath: StoragePaths.customerProofThumb(userId),
      bytes: bytes,
      kind: ImageUploadKind.customerProof,
    );
  }

  Future<ImageUploadResult> _uploadPair({
    required String fullPath,
    required String thumbPath,
    required Uint8List bytes,
    required ImageUploadKind kind,
  }) async {
    final full = ImageCompressor.compress(bytes, kind).bytes;
    final thumb = ImageCompressor.thumbnail(bytes, kind).bytes;

    final results = await Future.wait([
      _put(fullPath, full),
      _put(thumbPath, thumb),
    ]);

    return ImageUploadResult(fullUrl: results[0], thumbUrl: results[1]);
  }

  Future<String> _put(String path, Uint8List bytes) async {
    try {
      final ref = _storage.ref(path);
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      if (path.contains('promo_banners')) {
        PromoBannerDebug.log(
          'Storage.upload put OK path=$path downloadUrl=$url',
        );
      }
      return url;
    } catch (e, st) {
      if (path.contains('promo_banners')) {
        PromoBannerDebug.exception(e, st);
      }
      rethrow;
    }
  }

  /// أرشفة الصورة الحالية قبل استبدالها.
  static Future<void> archiveBeforeReplace({
    required String entityType,
    required String entityId,
    required String field,
    String? imageUrl,
    String? thumbUrl,
  }) {
    return ImageArchiveService().archiveIfNeeded(
      entityType: entityType,
      entityId: entityId,
      field: field,
      imageUrl: imageUrl,
      thumbUrl: thumbUrl,
      archivedBy: AdminSession.instance.user?.uid,
    );
  }
}
