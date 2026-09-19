import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';
import 'package:matlobgo/screens/home/product/widgets/product_description_section.dart';

/// قسم الملاحظات: عنوان بقلم برتقالي + حقل رمادي + عدّاد 0/200.
class ProductNotesSection extends StatelessWidget {
  const ProductNotesSection({
    super.key,
    required this.controller,
    required this.length,
    required this.maxLength,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int length;
  final int maxLength;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: ProductSectionTitle(
                title: 'ملاحظات الطلب',
                icon: Icons.edit_outlined,
              ),
            ),
            Text(
              '$length/$maxLength',
              style: CartTypography.style(
                fontSize: ProductTokens.captionSize,
                fontWeight: FontWeight.w700,
                color: ProductTokens.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: ProductTokens.spaceLg),
        Semantics(
          textField: true,
          label: 'ملاحظات الطلب',
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 4,
            minLines: 3,
            maxLength: maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (
              _, {
              required currentLength,
              required isFocused,
              maxLength,
            }) =>
                null,
            textInputAction: TextInputAction.newline,
            style: CartTypography.style(
              fontSize: ProductTokens.bodySize,
              fontWeight: FontWeight.w500,
              color: ProductTokens.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'مثال: بدون بصل، زيادة صوص، الخبز محمّص...',
              hintStyle: CartTypography.style(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ProductTokens.textMuted,
              ),
              filled: true,
              fillColor: ProductTokens.fieldFill,
              contentPadding: const EdgeInsets.all(ProductTokens.space2xl),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ProductTokens.radiusMd),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ProductTokens.radiusMd),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ProductTokens.radiusMd),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
