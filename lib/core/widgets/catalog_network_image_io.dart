import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:matlobgo/core/utils/catalog_image_cache.dart';
import 'package:matlobgo/core/utils/catalog_image_diagnostics.dart';
import 'package:matlobgo/core/utils/catalog_image_storage_resolver.dart';
import 'package:matlobgo/core/utils/catalog_image_url_resolver.dart';
import 'package:matlobgo/core/utils/catalog_image_urls.dart';
import 'package:matlobgo/core/utils/promo_banner_debug.dart';

/// صورة كatalog — تعرض من القرص فوراً إن وُجدت، وإلا تنزّل مع cache.
class CatalogNetworkImage extends StatefulWidget {
  const CatalogNetworkImage({
    super.key,
    this.imageUrl,
    this.thumbnailUrl,
    required this.fallback,
    this.placeholder,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.cacheWidth,
    this.cacheHeight,
    this.useFullResolution = false,
    this.debugTag,
  });

  final String? imageUrl;
  final String? thumbnailUrl;
  final Widget fallback;
  final Widget? placeholder;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius? borderRadius;
  final int? cacheWidth;
  final int? cacheHeight;
  final bool useFullResolution;
  final String? debugTag;

  static Future<void> prefetch(Iterable<String?> urls) =>
      CatalogImageCache.prefetch(urls);

  @override
  State<CatalogNetworkImage> createState() => _CatalogNetworkImageState();
}

class _CatalogNetworkImageState extends State<CatalogNetworkImage> {
  File? _cachedFile;
  late List<String> _candidates;
  int _candidateIndex = 0;
  bool _exhausted = false;
  bool _advancing = false;
  bool _storageResolveAttempted = false;

  @override
  void initState() {
    super.initState();
    _rebuildCandidates();
    _loadCachedFile();
  }

  @override
  void didUpdateWidget(CatalogNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.thumbnailUrl != widget.thumbnailUrl ||
        oldWidget.useFullResolution != widget.useFullResolution) {
      _rebuildCandidates();
      _storageResolveAttempted = false;
      _loadCachedFile();
    }
  }

  void _rebuildCandidates() {
    _candidates = catalogImageCandidateUrls(
      thumbnailUrl: widget.thumbnailUrl,
      imageUrl: widget.imageUrl,
      useFullResolution: widget.useFullResolution,
    );
    _candidateIndex = 0;
    _exhausted = _candidates.isEmpty;
    _advancing = false;
    _storageResolveAttempted = false;
    if (widget.debugTag != null && widget.debugTag!.startsWith('PromoBanner')) {
      final id = widget.debugTag!.replaceFirst('PromoBanner:', '');
      PromoBannerDebug.log(
        'Image.candidates ID: $id count=${_candidates.length} '
        'bucket=${CatalogImageUrlResolver.defaultBucket} urls=$_candidates',
      );
      if (_candidates.isEmpty) {
        PromoBannerDebug.imageIssue(
          bannerId: id,
          reason: 'imageUrl empty/null (no load candidates)',
          url: widget.imageUrl,
        );
      }
    }
  }

  String? get _resolvedUrl =>
      _candidateIndex < _candidates.length ? _candidates[_candidateIndex] : null;

  Future<void> _loadCachedFile() async {
    final url = _resolvedUrl;
    if (url == null || url.isEmpty) {
      if (mounted && _cachedFile != null) {
        setState(() => _cachedFile = null);
      }
      return;
    }

    if (CatalogImageCache.isKnownFailed(url)) {
      await _advanceToNextCandidate();
      return;
    }

    FileInfo? info = await CatalogImageCache.manager.getFileFromCache(url);
    info ??= await _tryDownload(url);

    if (!mounted) return;
    final file = info?.file;
    if (file == null) {
      await _advanceToNextCandidate();
      return;
    }
    if (_cachedFile?.path != file.path) {
      setState(() => _cachedFile = file);
    }
  }

  Future<FileInfo?> _tryDownload(String url) async {
    if (CatalogImageCache.isKnownFailed(url)) return null;
    try {
      CatalogImageDiagnostics.logAttempt(url: url);
      final info = await CatalogImageCache.downloadWithTimeout(url);
      if (info != null) {
        CatalogImageDiagnostics.logSuccess(url: url);
      }
      return info;
    } catch (error, stackTrace) {
      CatalogImageCache.markFailedIfPermanent(url, error);
      CatalogImageDiagnostics.logFailure(
        url: url,
        error: error,
        stackTrace: stackTrace,
      );
      if (widget.debugTag != null &&
          widget.debugTag!.startsWith('PromoBanner')) {
        final id = widget.debugTag!.replaceFirst('PromoBanner:', '');
        final msg = error.toString();
        final reason = msg.contains('404')
            ? '404 (file missing in Storage)'
            : msg.contains('403')
                ? '403 (Storage permission denied)'
                : 'CachedNetworkImage download failed';
        PromoBannerDebug.imageIssue(
          bannerId: id,
          reason: reason,
          url: url,
          error: error,
        );
        PromoBannerDebug.exception(error, stackTrace);
      }
      return null;
    }
  }

  Future<void> _advanceToNextCandidate() async {
    if (!mounted || _advancing) return;
    _advancing = true;
    try {
      if (_candidateIndex + 1 < _candidates.length) {
        _candidateIndex++;
        _cachedFile = null;
        await _loadCachedFile();
        if (mounted) setState(() {});
      } else {
        await _tryStorageResolveFallback();
      }
    } finally {
      _advancing = false;
    }
  }

  Future<void> _tryStorageResolveFallback() async {
    if (!mounted || _storageResolveAttempted) {
      if (mounted && !_exhausted) setState(() => _exhausted = true);
      return;
    }
    _storageResolveAttempted = true;

    final freshUrl = await CatalogImageStorageResolver.resolveFromFields(
      thumbnailUrl: widget.thumbnailUrl,
      imageUrl: widget.imageUrl,
    );
    if (!mounted) return;

    if (freshUrl != null &&
        freshUrl.isNotEmpty &&
        !_candidates.contains(freshUrl)) {
      _candidates = [..._candidates, freshUrl];
      _candidateIndex = _candidates.length - 1;
      _exhausted = false;
      _cachedFile = null;
      await _loadCachedFile();
      if (mounted) setState(() {});
      return;
    }

    if (mounted) setState(() => _exhausted = true);
  }

  void _onNetworkError(String url) {
    CatalogImageCache.markFailed(url);
    unawaited(_advanceToNextCandidate());
  }

  @override
  Widget build(BuildContext context) {
    if (_candidates.isEmpty || _exhausted) {
      return _wrap(widget.fallback);
    }

    final url = _resolvedUrl;
    if (url == null || url.isEmpty) {
      return _wrap(widget.fallback);
    }

    if (CatalogImageCache.isKnownFailed(url)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_advanceToNextCandidate());
      });
      return _wrap(widget.fallback);
    }

    if (_cachedFile != null) {
      return _wrap(
        Image.file(
          _cachedFile!,
          fit: widget.fit,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          filterQuality: FilterQuality.low,
          errorBuilder: (_, error, stackTrace) {
            if (widget.debugTag != null &&
                widget.debugTag!.startsWith('PromoBanner')) {
              final id = widget.debugTag!.replaceFirst('PromoBanner:', '');
              PromoBannerDebug.imageIssue(
                bannerId: id,
                reason: 'Image.file decode failed',
                error: error,
              );
              PromoBannerDebug.exception(error, stackTrace);
            }
            return widget.fallback;
          },
        ),
      );
    }

    final memW = widget.cacheWidth;
    final memH = widget.cacheHeight;

    return _wrap(
      CachedNetworkImage(
        cacheManager: CatalogImageCache.manager,
        imageUrl: url,
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: memW,
        memCacheHeight: memH,
        maxWidthDiskCache: memW,
        maxHeightDiskCache: memH,
        filterQuality: FilterQuality.low,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        useOldImageOnUrlChange: true,
        placeholder: (_, _) => widget.placeholder ?? widget.fallback,
        errorWidget: (_, failedUrl, error) {
          if (widget.debugTag != null &&
              widget.debugTag!.startsWith('PromoBanner')) {
            final id = widget.debugTag!.replaceFirst('PromoBanner:', '');
            final msg = error.toString();
            final reason = msg.contains('404')
                ? '404 (file missing in Storage)'
                : msg.contains('403')
                    ? '403 (Storage permission denied)'
                    : 'CachedNetworkImage errorWidget';
            PromoBannerDebug.imageIssue(
              bannerId: id,
              reason: reason,
              url: failedUrl,
              error: error,
            );
          }
          _onNetworkError(url);
          return widget.placeholder ?? widget.fallback;
        },
        imageBuilder: (context, imageProvider) {
          return Image(
            image: imageProvider,
            fit: widget.fit,
            alignment: widget.alignment,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
          );
        },
      ),
    );
  }

  Widget _wrap(Widget child) {
    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }
    return child;
  }
}
