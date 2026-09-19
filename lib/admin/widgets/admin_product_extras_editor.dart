import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/models/product_addon.dart';

class AdminProductExtrasEditor extends StatefulWidget {
  const AdminProductExtrasEditor({
    super.key,
    required this.ingredients,
    required this.addons,
    required this.onIngredientsChanged,
    required this.onAddonsChanged,
  });

  final List<String> ingredients;
  final List<ProductAddon> addons;
  final ValueChanged<List<String>> onIngredientsChanged;
  final ValueChanged<List<ProductAddon>> onAddonsChanged;

  @override
  State<AdminProductExtrasEditor> createState() =>
      _AdminProductExtrasEditorState();
}

class _AdminProductExtrasEditorState extends State<AdminProductExtrasEditor> {
  late final TextEditingController _ingredientsCtrl;

  @override
  void initState() {
    super.initState();
    _ingredientsCtrl = TextEditingController(
      text: widget.ingredients.join('، '),
    );
    _ingredientsCtrl.addListener(_syncIngredients);
  }

  @override
  void dispose() {
    _ingredientsCtrl.removeListener(_syncIngredients);
    _ingredientsCtrl.dispose();
    super.dispose();
  }

  void _syncIngredients() {
    final list = _ingredientsCtrl.text
        .split(RegExp(r'[,،]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    widget.onIngredientsChanged(list);
  }

  Future<void> _addAddon() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '5');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'إضافة اختيارية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PremiumInputField(controller: nameCtrl, label: 'الاسم'),
            const SizedBox(height: 8),
            PremiumInputField(
              controller: priceCtrl,
              label: 'السعر الإضافي (ج.م)',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;
    final next = List<ProductAddon>.from(widget.addons)
      ..add(
        ProductAddon(
          id: 'addon_${DateTime.now().millisecondsSinceEpoch}',
          name: nameCtrl.text.trim(),
          price: double.tryParse(priceCtrl.text.trim()) ?? 0,
        ),
      );
    widget.onAddonsChanged(next);
    nameCtrl.dispose();
    priceCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ingredientPreview = widget.ingredients.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'صفحة تفاصيل المنتج في التطبيق',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'المكونات تظهر في شبكة 2×2، والإضافات تظهر كخيارات اختيارية للعميل.',
            style: GoogleFonts.cairo(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          PremiumInputField(
            controller: _ingredientsCtrl,
            label: 'المكونات (مفصولة بفاصلة)',
          ),
          if (ingredientPreview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'معاينة في التطبيق',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ingredientPreview
                  .map(
                    (item) => Chip(
                      avatar: const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 18,
                      ),
                      label: Text(item, style: GoogleFonts.cairo(fontSize: 12)),
                      backgroundColor: AppColors.surfaceMuted,
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'إضافات اختيارية',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addAddon,
                icon: const Icon(Icons.add, size: 18),
                label: Text('إضافة', style: GoogleFonts.cairo()),
              ),
            ],
          ),
          if (widget.addons.isEmpty)
            Text(
              'بدون إضافات — سيظهر للعميل السعر الأساسي فقط.',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          for (final addon in widget.addons)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  addon.name,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  addon.price == 0
                      ? 'مجاني'
                      : '+${addon.price.toStringAsFixed(0)} ج.م',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: addon.isAvailable,
                      onChanged: (v) {
                        final next = widget.addons
                            .map(
                              (a) => a.id == addon.id
                                  ? a.copyWith(isAvailable: v)
                                  : a,
                            )
                            .toList();
                        widget.onAddonsChanged(next);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                      onPressed: () {
                        widget.onAddonsChanged(
                          widget.addons
                              .where((a) => a.id != addon.id)
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
