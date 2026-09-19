import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/services/cms_text_service.dart';

/// Unified search field — tap-to-open (mobile hero) or editable (web).
class CatalogSearchBar extends StatefulWidget {
  const CatalogSearchBar.tap({
    super.key,
    required this.onTap,
    this.showFilterButton = true,
  })  : controller = null,
        onSubmit = null,
        hintText = null;

  const CatalogSearchBar.editable({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.hintText,
  })  : onTap = null,
        showFilterButton = false;

  final VoidCallback? onTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmit;
  final String? hintText;
  final bool showFilterButton;

  @override
  State<CatalogSearchBar> createState() => _CatalogSearchBarState();
}

class _CatalogSearchBarState extends State<CatalogSearchBar> {
  bool _focused = false;
  bool _pressed = false;

  bool get _isTapMode => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    if (_isTapMode) {
      return _buildTapBar(context);
    }
    return _buildEditableBar(context);
  }

  Widget _buildTapBar(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: HomeTheme.animPress,
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _focused = v),
            borderRadius: HomeTheme.borderMd,
            splashColor: AppColors.primary.withValues(alpha: 0.06),
            highlightColor: AppColors.primary.withValues(alpha: 0.03),
            child: AnimatedContainer(
              duration: HomeTheme.animNormal,
              curve: Curves.easeOutCubic,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: HomeTheme.borderMd,
                border: Border.all(
                  color: _focused
                      ? AppColors.primary.withValues(alpha: 0.45)
                      : AppColors.borderLight,
                  width: _focused ? 1.5 : 1,
                ),
                boxShadow: HomeTheme.softShadowSearch,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: HomeTheme.borderSm,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: _RotatingSearchPlaceholder()),
                    if (widget.showFilterButton)
                      AnimatedContainer(
                        duration: HomeTheme.animNormal,
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _focused
                              ? AppColors.accentMuted
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 17,
                          color: _focused
                              ? AppColors.primary
                              : AppColors.textSecondary.withValues(alpha: 0.65),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableBar(BuildContext context) {
    final hint = widget.hintText ?? CmsTextService.instance.homeSearchHint();

    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(18),
      child: TextField(
        controller: widget.controller,
        onSubmitted: widget.onSubmit,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(color: AppColors.textHint),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.primary),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => widget.onSubmit?.call(widget.controller!.text),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _RotatingSearchPlaceholder extends StatefulWidget {
  const _RotatingSearchPlaceholder();

  @override
  State<_RotatingSearchPlaceholder> createState() =>
      _RotatingSearchPlaceholderState();
}

class _RotatingSearchPlaceholderState extends State<_RotatingSearchPlaceholder> {
  static const _interval = Duration(seconds: 2);
  static const _fadeDuration = Duration(milliseconds: 250);

  Timer? _timer;
  int _index = 0;
  List<String> _hints = CmsTextService.instance.homeSearchHints();

  @override
  void initState() {
    super.initState();
    CmsTextService.instance.addListener(_onCmsChanged);
    _restartTimer();
  }

  void _onCmsChanged() {
    final next = CmsTextService.instance.homeSearchHints();
    if (listEquals(next, _hints)) return;
    setState(() {
      _hints = next;
      _index = 0;
    });
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_hints.length <= 1) return;
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % _hints.length;
      });
    });
  }

  @override
  void dispose() {
    CmsTextService.instance.removeListener(_onCmsChanged);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hints = _hints;
    final text = hints.isEmpty
        ? CmsTextService.instance.homeSearchHint()
        : hints[_index % hints.length];

    return AnimatedSwitcher(
      duration: _fadeDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Text(
        text,
        key: ValueKey<String>(text),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: HomeTheme.chipLabel.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}
