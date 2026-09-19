import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/image_compressor.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';

/// Admin image pick + preview.
///
/// Parent [pendingBytes] is the restore source after ListView disposes this
/// State. Preview is always rebuilt from those bytes in [build].
class AdminImagePicker extends StatefulWidget {
  const AdminImagePicker({
    super.key,
    required this.label,
    required this.uploadKind,
    this.existingUrl,
    this.pendingBytes,
    this.aspectRatio = 16 / 9,
    this.onImageChanged,
  });

  final String label;
  final ImageUploadKind uploadKind;
  final String? existingUrl;

  /// Parent-owned pending bytes — restored automatically after State recreate.
  final Uint8List? pendingBytes;
  final double aspectRatio;
  final void Function(Uint8List? bytes, {bool cleared})? onImageChanged;

  @override
  State<AdminImagePicker> createState() => AdminImagePickerState();
}

class AdminImagePickerState extends State<AdminImagePicker> {
  Uint8List? _localBytes;
  bool _cleared = false;
  bool _compressing = false;
  String? _compressionNote;

  /// Unique per State instance so [Image.memory] never reuses a stale codec
  /// after ListView recreates this widget.
  late final int _mountEpoch;

  static const _logTag = '[AdminImagePicker]';

  void _log(String event) {
    if (!kDebugMode) return;
    debugPrint(
      '$_logTag $event | widget.hash=${widget.hashCode} '
      'state.hash=$hashCode mountEpoch=$_mountEpoch '
      'local=${_localBytes?.length ?? 0} '
      'parentPending=${widget.pendingBytes?.length ?? 0} '
      'display=${_displayBytes?.length ?? 0} cleared=$_cleared',
    );
  }

  /// Parent wins when present so scroll-recreate always shows the pick.
  Uint8List? get _displayBytes {
    if (_cleared && widget.pendingBytes == null) return null;
    return widget.pendingBytes ?? _localBytes;
  }

  Uint8List? get pendingBytes => _displayBytes;
  bool get hasPendingUpload => _displayBytes != null;
  bool get wasCleared => _cleared;

  void _syncFromParent(String reason) {
    final parent = widget.pendingBytes;
    if (parent != null) {
      _localBytes = parent;
      _cleared = false;
      _log('syncFromParent ($reason) restored len=${parent.length}');
      return;
    }
    if (_cleared) {
      _localBytes = null;
      _log('syncFromParent ($reason) cleared locally');
    }
  }

  @override
  void initState() {
    super.initState();
    _mountEpoch = identityHashCode(this);
    _syncFromParent('initState');
    _log('initState');
  }

  @override
  void didUpdateWidget(covariant AdminImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _log(
      'didUpdateWidget oldParent=${oldWidget.pendingBytes?.length ?? 0} '
      'newParent=${widget.pendingBytes?.length ?? 0}',
    );

    final parent = widget.pendingBytes;
    final oldParent = oldWidget.pendingBytes;

    if (parent != null) {
      // Always adopt parent bytes (Form is source of truth after pick).
      if (!identical(_localBytes, parent)) {
        _localBytes = parent;
        _cleared = false;
        _log('didUpdateWidget adopted parent bytes len=${parent.length}');
      }
    } else if (oldParent != null && parent == null) {
      // Parent explicitly cleared.
      _localBytes = null;
      _cleared = true;
      _log('didUpdateWidget parent cleared');
    }
  }

  @override
  void dispose() {
    _log('dispose');
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;

    _log('Image Picked path=${file.name}');
    setState(() {
      _compressing = true;
      _compressionNote = null;
    });

    try {
      final raw = await file.readAsBytes();
      final result = ImageCompressor.compress(raw, widget.uploadKind);

      if (!mounted) return;
      setState(() {
        _localBytes = result.bytes;
        _cleared = false;
        _compressionNote =
            'تم الضغط: ${ImageCompressor.formatBytes(result.originalBytes)} ← ${ImageCompressor.formatBytes(result.compressedBytes)}';
      });
      _log('Image Picked applied bytes=${result.bytes.length}');
      widget.onImageChanged?.call(result.bytes);
    } finally {
      if (mounted) setState(() => _compressing = false);
    }
  }

  void _clear() {
    setState(() {
      _localBytes = null;
      _cleared = true;
      _compressionNote = null;
    });
    _log('cleared');
    widget.onImageChanged?.call(null, cleared: true);
  }

  Widget _buildPreviewImage(Uint8List bytes) {
    // New Key after every State mount so codec/texture is not reused stale
    // after ListView disposed this Element on Flutter Web.
    final imageKey = ValueKey<String>(
      'admin_img_${_mountEpoch}_${bytes.length}_'
      '${identityHashCode(bytes)}',
    );
    _log('buildPreview Image key=$imageKey');
    return Image.memory(
      bytes,
      key: imageKey,
      fit: BoxFit.cover,
      gaplessPlayback: false,
      errorBuilder: (context, error, stackTrace) {
        _log('Image.memory ERROR: $error');
        if (kDebugMode) {
          debugPrint('$_logTag Image ERROR stack:\n$stackTrace');
        }
        // Retry once with a fresh provider if decode failed after remount.
        return Image(
          image: MemoryImage(bytes),
          fit: BoxFit.cover,
          gaplessPlayback: false,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _log('build');

    final bytes = _displayBytes;
    final showUrl =
        !_cleared && bytes == null && widget.existingUrl != null;

    if (bytes != null) {
      _log('build SHOWING preview bytes=${bytes.length}');
    } else if (showUrl) {
      _log('build SHOWING existingUrl');
    } else {
      _log('build SHOWING placeholder');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bytes != null)
                    _buildPreviewImage(bytes)
                  else if (showUrl)
                    CatalogNetworkImage(
                      imageUrl: widget.existingUrl,
                      fit: BoxFit.cover,
                      fallback: _placeholder(),
                    )
                  else
                    _placeholder(),
                  if (_compressing)
                    Container(
                      color: Colors.black38,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_compressionNote != null) ...[
          const SizedBox(height: 8),
          Text(
            _compressionNote!,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _compressing ? null : _pick,
              icon: const Icon(Icons.photo_library_outlined, size: 20),
              label: Text(
                bytes != null || showUrl ? 'تغيير الصورة' : 'اختيار صورة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
            ),
            if (bytes != null || showUrl) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: _compressing ? null : _clear,
                child: Text('إزالة', style: GoogleFonts.cairo()),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 40, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(
            'لم تُرفع صورة بعد',
            style: GoogleFonts.cairo(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
