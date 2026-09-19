import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// نوع الصورة — يحدد أبعاد الضغط والحد الأقصى للحجم.
enum ImageUploadKind {
  promoBanner,
  storeCategory,
  storeCover,
  storeLogo,
  product,
  customerProof,
}

class ImageUploadSettings {
  const ImageUploadSettings({
    required this.maxWidth,
    required this.maxHeight,
    this.quality = 82,
    this.maxBytes = 300 * 1024,
    this.minQuality = 48,
  });

  final int maxWidth;
  final int maxHeight;
  final int quality;
  final int maxBytes;
  final int minQuality;
}

class ImageCompressionResult {
  const ImageCompressionResult({
    required this.bytes,
    required this.originalBytes,
  });

  final Uint8List bytes;
  final int originalBytes;

  int get compressedBytes => bytes.length;

  double get ratio =>
      originalBytes == 0 ? 1 : compressedBytes / originalBytes;
}

/// ضغط وresize للصور قبل رفع Firebase Storage.
class ImageCompressor {
  ImageCompressor._();

  static ImageUploadSettings settingsFor(ImageUploadKind kind) {
    return switch (kind) {
      ImageUploadKind.promoBanner => const ImageUploadSettings(
          maxWidth: 1200,
          maxHeight: 560,
          quality: 82,
          maxBytes: 280 * 1024,
        ),
      ImageUploadKind.storeCategory => const ImageUploadSettings(
          maxWidth: 800,
          maxHeight: 1000,
          quality: 82,
          maxBytes: 200 * 1024,
        ),
      ImageUploadKind.storeCover => const ImageUploadSettings(
          maxWidth: 900,
          maxHeight: 520,
          quality: 82,
          maxBytes: 240 * 1024,
        ),
      ImageUploadKind.storeLogo => const ImageUploadSettings(
          maxWidth: 512,
          maxHeight: 512,
          quality: 82,
          maxBytes: 120 * 1024,
        ),
      ImageUploadKind.product => const ImageUploadSettings(
          maxWidth: 720,
          maxHeight: 720,
          quality: 80,
          maxBytes: 180 * 1024,
        ),
      ImageUploadKind.customerProof => const ImageUploadSettings(
          maxWidth: 1280,
          maxHeight: 1280,
          quality: 82,
          maxBytes: 400 * 1024,
        ),
    };
  }

  /// مصغّرة للقوائم — ملف صغير يُحمَّل فوراً في الرئيسية.
  static ImageUploadSettings thumbnailSettingsFor(ImageUploadKind kind) {
    return switch (kind) {
      ImageUploadKind.promoBanner => const ImageUploadSettings(
          maxWidth: 480,
          maxHeight: 225,
          quality: 68,
          maxBytes: 28 * 1024,
          minQuality: 40,
        ),
      ImageUploadKind.storeCategory => const ImageUploadSettings(
          maxWidth: 174,
          maxHeight: 222,
          quality: 68,
          maxBytes: 18 * 1024,
          minQuality: 40,
        ),
      ImageUploadKind.storeCover => const ImageUploadSettings(
          maxWidth: 360,
          maxHeight: 210,
          quality: 68,
          maxBytes: 22 * 1024,
          minQuality: 40,
        ),
      ImageUploadKind.storeLogo => const ImageUploadSettings(
          maxWidth: 128,
          maxHeight: 128,
          quality: 70,
          maxBytes: 16 * 1024,
          minQuality: 40,
        ),
      ImageUploadKind.product => const ImageUploadSettings(
          maxWidth: 210,
          maxHeight: 210,
          quality: 68,
          maxBytes: 20 * 1024,
          minQuality: 40,
        ),
      ImageUploadKind.customerProof => const ImageUploadSettings(
          maxWidth: 360,
          maxHeight: 360,
          quality: 68,
          maxBytes: 40 * 1024,
          minQuality: 40,
        ),
    };
  }

  static ImageCompressionResult thumbnail(
    Uint8List input,
    ImageUploadKind kind,
  ) {
    return compressWithSettings(input, thumbnailSettingsFor(kind));
  }

  static ImageCompressionResult compress(
    Uint8List input,
    ImageUploadKind kind,
  ) {
    return compressWithSettings(input, settingsFor(kind));
  }

  static ImageCompressionResult compressWithSettings(
    Uint8List input,
    ImageUploadSettings settings,
  ) {
    final originalBytes = input.length;
    final decoded = img.decodeImage(input);

    if (decoded == null) {
      return ImageCompressionResult(bytes: input, originalBytes: originalBytes);
    }

    var image = img.bakeOrientation(decoded);
    image = _fitWithin(image, settings.maxWidth, settings.maxHeight);

    var quality = settings.quality;
    var encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));

    while (encoded.length > settings.maxBytes && quality > settings.minQuality) {
      quality -= 7;
      encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
    }

    return ImageCompressionResult(
      bytes: encoded,
      originalBytes: originalBytes,
    );
  }

  static img.Image _fitWithin(img.Image image, int maxW, int maxH) {
    if (image.width <= maxW && image.height <= maxH) return image;

    final scaleW = maxW / image.width;
    final scaleH = maxH / image.height;
    final scale = scaleW < scaleH ? scaleW : scaleH;

    final newW = (image.width * scale).round().clamp(1, maxW);
    final newH = (image.height * scale).round().clamp(1, maxH);

    return img.copyResize(
      image,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.linear,
    );
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
