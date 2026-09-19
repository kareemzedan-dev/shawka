import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/services/driver_rating_service.dart';

Future<bool?> showDriverRatingSheet(
  BuildContext context, {
  required Order order,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _DriverRatingSheet(order: order),
  );
}

class _DriverRatingSheet extends StatefulWidget {
  const _DriverRatingSheet({required this.order});

  final Order order;

  @override
  State<_DriverRatingSheet> createState() => _DriverRatingSheetState();
}

class _DriverRatingSheetState extends State<_DriverRatingSheet> {
  final _service = DriverRatingService();
  int _rating = 5;
  bool _saving = false;

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await _service.submitRating(
        orderId: widget.order.id,
        rating: _rating,
      );
      if (mounted) Navigator.pop(context, true);
    } on DriverRatingException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message,
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذّر إرسال التقييم — حاول مرة أخرى',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.order.deliveryName ?? 'المندوب';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'قيّم تجربة التوصيل',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'كيف كان أداء $name؟',
            style: GoogleFonts.cairo(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                onPressed: _saving ? null : () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFFB300),
                  size: 40,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('إرسال التقييم', style: GoogleFonts.cairo()),
            ),
          ),
        ],
      ),
    );
  }
}
