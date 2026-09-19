import 'package:flutter/material.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_glass.dart';

class TarfaSearchBar extends StatelessWidget {
  const TarfaSearchBar({
    super.key,
    this.controller,
    this.hint = 'ابحث عن مورد، منتج، أو متجر...',
    this.onTap,
    this.onSubmitted,
    this.onChanged,
    this.readOnly = false,
    this.autofocus = false,
    this.large = false,
    this.showLocation = false,
    this.locationLabel,
    this.onLocationTap,
  });

  final TextEditingController? controller;
  final String hint;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool autofocus;
  final bool large;
  final bool showLocation;
  final String? locationLabel;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    final height = large ? 60.0 : 52.0;

    return TarfaGlass(
      borderRadius: BorderRadius.circular(large ? TarfaTokens.radiusLg : TarfaTokens.radius),
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            if (showLocation && locationLabel != null) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onLocationTap,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(TarfaTokens.radiusLg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: TarfaTokens.s16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: TarfaTokens.secondary,
                          size: 22,
                        ),
                        const SizedBox(width: TarfaTokens.s8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            locationLabel!,
                            style: TarfaTokens.labelLarge(context).copyWith(
                              color: TarfaTokens.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: TarfaTokens.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: TarfaTokens.divider,
              ),
            ],
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: readOnly,
                autofocus: autofocus,
                onTap: onTap,
                onSubmitted: onSubmitted,
                onChanged: onChanged,
                style: TarfaTokens.bodyLarge(context).copyWith(
                  color: TarfaTokens.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TarfaTokens.bodyMedium(context),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: TarfaTokens.textMuted,
                    size: 24,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TarfaTokens.s8,
                    vertical: TarfaTokens.s16,
                  ),
                ),
              ),
            ),
            if (large)
              Padding(
                padding: const EdgeInsets.only(left: TarfaTokens.s8),
                child: FilledButton(
                  onPressed: () {
                    onSubmitted?.call(controller?.text ?? '');
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(56, 48),
                    padding: const EdgeInsets.symmetric(horizontal: TarfaTokens.s24),
                  ),
                  child: const Text('بحث'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
