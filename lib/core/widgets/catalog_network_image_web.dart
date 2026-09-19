import 'dart:async';

import 'package:flutter/material.dart';
import 'package:matlobgo/core/utils/catalog_image_cache.dart';
import 'package:matlobgo/core/utils/catalog_image_diagnostics.dart';
import 'package:matlobgo/core/utils/catalog_image_storage_resolver.dart';
import 'package:matlobgo/core/utils/catalog_image_url_resolver.dart';
import 'package:matlobgo/core/utils/catalog_image_urls.dart';
import 'package:matlobgo/core/utils/promo_banner_debug.dart';

/// Web catalog image — canvas decode (CORS enabled on Storage) so [BoxFit]
/// and layout sizing work correctly. HTML-prefer broke cover/contain fills.
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
  late List<String> _candidates;
  int _candidateIndex = 0;
  bool _exhausted = false;
  bool _storageResolveAttempted = false;
  final Set<String> _reportedErrors = {};

  Widget get _loadingSlot =>
      widget.placeholder ??
      ColoredBox(
        color: const Color(0xFFE2E8F0),
        child: widget.fallback,
      );

  @override
  void initState() {
    super.initState();
    _rebuildCandidates();
  }

  @override
  void didUpdateWidget(CatalogNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.thumbnailUrl != widget.thumbnailUrl ||
        oldWidget.useFullResolution != widget.useFullResolution) {
      _reportedErrors.clear();
      _storageResolveAttempted = false;
      _rebuildCandidates();
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
      setState(() {
        _candidates = [..._candidates, freshUrl];
        _candidateIndex = _candidates.length - 1;
        _exhausted = false;
      });
      return;
    }

    if (mounted) setState(() => _exhausted = true);
  }

  void _tryNextCandidate(Object error, StackTrace? stackTrace) {
    final url = _activeUrl;
    if (url != null && !_reportedErrors.contains(url)) {
      _reportedErrors.add(url);
      CatalogImageDiagnostics.logFailure(
        url: url,
        error: error,
        stackTrace: stackTrace,
        tag: widget.debugTag ?? 'CatalogNetworkImage',
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_candidateIndex + 1 < _candidates.length) {
        setState(() => _candidateIndex++);
        return;
      }
      unawaited(_tryStorageResolveFallback());
    });
  }

  String? get _activeUrl =>
      _candidateIndex < _candidates.length ? _candidates[_candidateIndex] : null;

  @override
  Widget build(BuildContext context) {
    if (_candidates.isEmpty || _exhausted) {
      return _wrap(
        SizedBox.expand(child: widget.fallback),
      );
    }

    final url = _activeUrl!;
    CatalogImageDiagnostics.logAttempt(
      url: url,
      tag: widget.debugTag ?? 'CatalogNetworkImage',
      candidateIndex: '${_candidateIndex + 1}/${_candidates.length}',
    );

    return _wrap(
      LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final bounded = w.isFinite &&
              h.isFinite &&
              w > 0 &&
              h > 0 &&
              constraints.hasBoundedWidth &&
              constraints.hasBoundedHeight;

          // Canvas decode respects BoxFit; CORS is configured on the bucket.
          final network = Image.network(
            url,
            key: ValueKey(url),
            fit: widget.fit,
            alignment: widget.alignment,
            width: bounded ? w : double.infinity,
            height: bounded ? h : double.infinity,
            filterQuality: FilterQuality.medium,
            webHtmlElementStrategy: WebHtmlElementStrategy.never,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, wasSync) {
              final ready = wasSync || frame != null;
              if (ready) {
                CatalogImageDiagnostics.logSuccess(
                  url: url,
                  tag: widget.debugTag ?? 'CatalogNetworkImage',
                );
              }
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(child: _loadingSlot),
                  if (ready) Positioned.fill(child: child),
                ],
              );
            },
            errorBuilder: (context, error, stackTrace) {
              if (widget.debugTag != null &&
                  widget.debugTag!.startsWith('PromoBanner')) {
                final id = widget.debugTag!.replaceFirst('PromoBanner:', '');
                final msg = error.toString();
                final reason = msg.contains('404')
                    ? '404 (file missing in Storage)'
                    : msg.toLowerCase().contains('cors')
                        ? 'CORS blocked (configure Storage CORS)'
                        : 'Image.network failed';
                PromoBannerDebug.imageIssue(
                  bannerId: id,
                  reason: reason,
                  url: url,
                  error: error,
                );
                PromoBannerDebug.exception(error, stackTrace);
              }
              _tryNextCandidate(error, stackTrace);
              return _loadingSlot;
            },
          );

          if (!bounded) {
            return network;
          }

          return SizedBox(width: w, height: h, child: network);
        },
      ),
    );
  }

  Widget _wrap(Widget child) {
    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    }
    return child;
  }
}
