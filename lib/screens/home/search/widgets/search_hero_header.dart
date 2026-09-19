import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/search_tokens.dart';

/// هيرو شاشة البحث: رجوع + عنوان + فلتر + حقل بحث + ميكروفون.
class SearchHeroHeader extends StatelessWidget {
  const SearchHeroHeader({
    super.key,
    required this.topPadding,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.title,
    required this.onChanged,
    required this.onBack,
    required this.onFilterTap,
    required this.onVoiceTap,
    required this.onClear,
    required this.hasText,
  });

  final double topPadding;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String title;
  final ValueChanged<String> onChanged;
  final VoidCallback onBack;
  final VoidCallback onFilterTap;
  final VoidCallback onVoiceTap;
  final VoidCallback onClear;
  final bool hasText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: SearchTokens.heroGradient),
      padding: EdgeInsets.fromLTRB(
        SearchTokens.pagePadding,
        topPadding + 8,
        SearchTokens.pagePadding,
        22,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _GlassIconButton(
                icon: Icons.arrow_forward_ios_rounded,
                semanticLabel: 'رجوع',
                onTap: onBack,
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: CartTypography.style(
                    fontSize: SearchTokens.titleSize,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              _GlassIconButton(
                icon: Icons.tune_rounded,
                semanticLabel: 'تصفية',
                onTap: onFilterTap,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: SearchTokens.searchFieldHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(SearchTokens.searchFieldRadius),
              boxShadow: SearchTokens.searchFieldShadow,
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: CartTypography.style(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SearchTokens.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: CartTypography.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: SearchTokens.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasText)
                      IconButton(
                        tooltip: 'مسح',
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: SearchTokens.textSecondary,
                      ),
                    Semantics(
                      button: true,
                      label: 'بحث صوتي',
                      child: IconButton(
                        onPressed: onVoiceTap,
                        icon: const Icon(Icons.mic_rounded, size: 22),
                        color: SearchTokens.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: SearchTokens.glassFill,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: SearchTokens.headerButton,
            height: SearchTokens.headerButton,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
