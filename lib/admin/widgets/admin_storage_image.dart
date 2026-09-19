import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:matlobgo/core/utils/catalog_image_url_resolver.dart';

/// Loads private Storage proof images for admin.
///
/// Always decodes to bytes then paints with [Image.memory] so BoxFit / dialog
/// layout work on Flutter web (HTML `<img>` platform views break sizing).
class AdminStorageImage extends StatefulWidget {
  const AdminStorageImage({
    super.key,
    required this.imageUrl,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.maxBytes = 12 * 1024 * 1024,
  });

  final String imageUrl;
  final Widget fallback;
  final BoxFit fit;
  final Alignment alignment;
  final int maxBytes;

  static final Map<String, Uint8List> _bytesCache = {};

  static void clearCache() => _bytesCache.clear();

  @override
  State<AdminStorageImage> createState() => _AdminStorageImageState();
}

class _AdminStorageImageState extends State<AdminStorageImage> {
  Uint8List? _bytes;
  bool _loading = true;
  String? _loadKey;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(AdminStorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      unawaited(_load());
    }
  }

  String? _objectPath(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final fromUrl = CatalogImageUrlResolver.extractStorageObjectPath(trimmed);
    if (fromUrl != null && fromUrl.isNotEmpty) return fromUrl;
    if (!trimmed.contains('://') && trimmed.contains('/')) return trimmed;
    return null;
  }

  Future<Uint8List?> _fetchViaSdk(String path) async {
    return FirebaseStorage.instance.ref(path).getData(widget.maxBytes);
  }

  Future<Uint8List?> _fetchViaHttp(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      if (res.bodyBytes.isEmpty || res.bodyBytes.length > widget.maxBytes) {
        return null;
      }
      return res.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    final raw = widget.imageUrl.trim();
    final path = _objectPath(raw);
    final key = path ?? raw;
    _loadKey = key;

    if (raw.isEmpty) {
      setState(() {
        _bytes = null;
        _loading = false;
      });
      return;
    }

    final cached = AdminStorageImage._bytesCache[key];
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _bytes = cached;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _bytes = null;
    });

    Uint8List? bytes;

    // 1) Authenticated SDK download (works with Storage rules + CORS).
    if (path != null && path.isNotEmpty) {
      try {
        bytes = await _fetchViaSdk(path);
      } catch (_) {
        bytes = null;
      }
    }

    // 2) Tokenized download URL over HTTP (CORS now enabled on bucket).
    if ((bytes == null || bytes.isEmpty) && raw.startsWith('http')) {
      bytes = await _fetchViaHttp(raw);
    }

    if ((bytes == null || bytes.isEmpty) && path != null) {
      try {
        final fresh = await FirebaseStorage.instance.ref(path).getDownloadURL();
        bytes = await _fetchViaHttp(fresh);
      } catch (_) {
        bytes = null;
      }
    }

    if (!mounted || _loadKey != key) return;

    if (bytes != null && bytes.isNotEmpty) {
      AdminStorageImage._bytesCache[key] = bytes;
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
      return;
    }

    setState(() {
      _bytes = null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: Color(0xFF111827),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    final bytes = _bytes;
    if (bytes == null || bytes.isEmpty) {
      return widget.fallback;
    }

    return ColoredBox(
      color: const Color(0xFF111827),
      child: Image.memory(
        bytes,
        fit: widget.fit,
        alignment: widget.alignment,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => widget.fallback,
      ),
    );
  }
}
