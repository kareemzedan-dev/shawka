import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/utils/audit_diff.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/delivery_pricing_tier.dart';
import 'package:matlobgo/repositories/app_settings_repository.dart';
import 'package:matlobgo/repositories/delivery_pricing_analytics_repository.dart';

class AdminDeliveryPricingPanel extends StatefulWidget {
  const AdminDeliveryPricingPanel({super.key});

  @override
  State<AdminDeliveryPricingPanel> createState() =>
      _AdminDeliveryPricingPanelState();
}

class _AdminDeliveryPricingPanelState extends State<AdminDeliveryPricingPanel> {
  final _repo = AppSettingsRepository();
  final _analytics = DeliveryPricingAnalyticsRepository();
  final _formKey = GlobalKey<FormState>();

  final _maxRoadKm = TextEditingController();
  final _freeThreshold = TextEditingController();
  final _tierControllers = <_TierRowControllers>[];

  AppSettings? _before;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _maxRoadKm.dispose();
    _freeThreshold.dispose();
    for (final row in _tierControllers) {
      row.dispose();
    }
    super.dispose();
  }

  void _apply(AppSettings settings) {
    _before = settings;
    _maxRoadKm.text = settings.deliveryMaxRoadKm.toString();
    _freeThreshold.text = settings.freeDeliveryThreshold.toString();
    for (final row in _tierControllers) {
      row.dispose();
    }
    _tierControllers
      ..clear()
      ..addAll(
        settings.deliveryPricingTiers.map(_TierRowControllers.fromTier),
      );
    _loaded = true;
  }

  AppSettings _build() {
    final prev = _before ?? const AppSettings();
    final tiers = _tierControllers
        .map((c) => c.toTier())
        .where((t) => t.maxKm > t.minKm)
        .toList()
      ..sort((a, b) => a.minKm.compareTo(b.minKm));

    return prev.copyWith(
      deliveryMaxRoadKm: double.tryParse(_maxRoadKm.text.trim()) ?? 15,
      freeDeliveryThreshold:
          double.tryParse(_freeThreshold.text.trim()) ?? 300,
      deliveryPricingTiers:
          tiers.isEmpty ? DeliveryPricingTier.defaults : tiers,
      enableDistanceBasedDeliveryFee: true,
    );
  }

  void _addTier() {
    setState(() {
      final lastMax = _tierControllers.isEmpty
          ? 0.0
          : double.tryParse(_tierControllers.last.maxKm.text.trim()) ?? 0;
      _tierControllers.add(
        _TierRowControllers(
          minKm: TextEditingController(text: lastMax.toString()),
          maxKm: TextEditingController(text: (lastMax + 3).toString()),
          fee: TextEditingController(text: '15'),
        ),
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final next = _build();
      await _repo.save(next);
      await AdminSession.instance.recordWithDiff(
        action: AuditAction.update,
        entityType: 'delivery_pricing',
        entityId: AppSettings.documentId,
        summary: 'تحديث شرائح رسوم التوصيل',
        before: _before != null
            ? AuditDiff.snapshot(_before!.toFirestore())
            : null,
        after: AuditDiff.snapshot(next.toFirestore()),
      );
      _before = next;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ تسعير التوصيل')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirestoreErrorMessage.from(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppSettings>(
      stream: _repo.watch(),
      builder: (context, snapshot) {
        if (snapshot.hasData && !_loaded) {
          _apply(snapshot.data!);
        }
        if (snapshot.connectionState == ConnectionState.waiting && !_loaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminPanelHeader(
                title: 'Delivery Pricing',
                subtitle:
                    'شرائح رسوم التوصيل حسب مسافة الطريق — التغيير يظهر فوراً في التطبيق',
                trailing: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    'حفظ',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: StreamBuilder<DeliveryPricingStats>(
                  stream: _analytics.watchStats(),
                  builder: (context, statsSnap) {
                    final stats = statsSnap.data;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'إحصائيات التوصيل',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _StatChip(
                                  label: 'متوسط المسافة',
                                  value:
                                      '${(stats?.averageDistanceKm ?? 0).toStringAsFixed(1)} كم',
                                ),
                                _StatChip(
                                  label: 'متوسط الرسوم',
                                  value:
                                      '${(stats?.averageFee ?? 0).toStringAsFixed(0)} ج',
                                ),
                                _StatChip(
                                  label: 'خارج النطاق',
                                  value: '${stats?.outOfZoneQuotes ?? 0}',
                                  color: AppColors.error,
                                ),
                              ],
                            ),
                            if (stats?.topAreas.isNotEmpty == true) ...[
                              const SizedBox(height: 10),
                              Text(
                                'أكثر المناطق طلباً: ${stats!.topAreas.map((e) => '${e.key} (${e.value})').join(' · ')}',
                                style: GoogleFonts.cairo(fontSize: 12),
                              ),
                            ],
                            if (stats?.topUnservedAreas.isNotEmpty == true) ...[
                              const SizedBox(height: 6),
                              Text(
                                'مناطق غير مخدومة: ${stats!.topUnservedAreas.map((e) => '${e.key} (${e.value})').join(' · ')}',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'الإعدادات العامة',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: PremiumInputField(
                                  controller: _maxRoadKm,
                                  label: 'أقصى مسافة توصيل (كم)',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PremiumInputField(
                                  controller: _freeThreshold,
                                  label: 'توصيل مجاني فوق (ج.م)',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'شرائح التسعير',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _addTier,
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(
                                  'شريحة',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (var i = 0; i < _tierControllers.length; i++)
                            _TierEditorRow(
                              controllers: _tierControllers[i],
                              onRemove: _tierControllers.length > 1
                                  ? () => setState(
                                        () => _tierControllers.removeAt(i),
                                      )
                                  : null,
                            ),
                          const SizedBox(height: 8),
                          Text(
                            'أكثر من ${_maxRoadKm.text.trim().isEmpty ? '15' : _maxRoadKm.text} كم = غير متاح للتوصيل',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TierRowControllers {
  _TierRowControllers({
    required this.minKm,
    required this.maxKm,
    required this.fee,
  });

  factory _TierRowControllers.fromTier(DeliveryPricingTier tier) {
    return _TierRowControllers(
      minKm: TextEditingController(text: tier.minKm.toString()),
      maxKm: TextEditingController(text: tier.maxKm.toString()),
      fee: TextEditingController(text: tier.fee.toString()),
    );
  }

  final TextEditingController minKm;
  final TextEditingController maxKm;
  final TextEditingController fee;

  DeliveryPricingTier toTier() => DeliveryPricingTier(
        minKm: double.tryParse(minKm.text.trim()) ?? 0,
        maxKm: double.tryParse(maxKm.text.trim()) ?? 0,
        fee: double.tryParse(fee.text.trim()) ?? 0,
      );

  void dispose() {
    minKm.dispose();
    maxKm.dispose();
    fee.dispose();
  }
}

class _TierEditorRow extends StatelessWidget {
  const _TierEditorRow({
    required this.controllers,
    this.onRemove,
  });

  final _TierRowControllers controllers;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: PremiumInputField(
              controller: controllers.minKm,
              label: 'من (كم)',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PremiumInputField(
              controller: controllers.maxKm,
              label: 'إلى (كم)',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PremiumInputField(
              controller: controllers.fee,
              label: 'الرسوم (ج)',
              keyboardType: TextInputType.number,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
