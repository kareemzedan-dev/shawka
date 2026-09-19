import 'package:flutter/material.dart';
import 'package:matlobgo/core/legal/app_legal_content.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/profile_tokens.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:url_launcher/url_launcher.dart';

/// شاشة مستند قانوني قابل للتمرير (سياسة الخصوصية / الشروط والأحكام).
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.document,
  });

  final AppLegalDocument document;

  static Future<void> open(
    BuildContext context, {
    required AppLegalDocument document,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = AppLegalContent.titleFor(document);
    final sections = AppLegalContent.sectionsFor(document);
    final publicUrl = AppLegalContent.urlFor(document).trim();
    final hasPublicUrl = publicUrl.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: PremiumBackground.scaffoldColor(context),
        appBar: AppBar(
          backgroundColor: PremiumBackground.scaffoldColor(context),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: ProfileTokens.textPrimary,
          ),
          title: Text(
            title,
            style: CartTypography.style(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ProfileTokens.textPrimary,
            ),
          ),
        ),
        body: PremiumBackground.body(
          context,
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                AppLegalContent.lastUpdatedLabel,
                style: CartTypography.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ProfileTokens.textSecondary,
                ),
              ),
              if (hasPublicUrl) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => _openPublicUrl(publicUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('فتح النسخة العامة على الويب'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ProfileTokens.accent,
                    side: BorderSide(
                      color: ProfileTokens.accent.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              for (final section in sections) ...[
                if (section.heading.isNotEmpty) ...[
                  Text(
                    section.heading,
                    style: CartTypography.style(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ProfileTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (section.paragraphs.isNotEmpty) ...[
                  Text(
                    section.paragraphs.first,
                    style: CartTypography.style(
                      fontSize: 14,
                      height: 1.65,
                      color: ProfileTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                for (final bullet in section.bullets) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, right: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '•  ',
                          style: CartTypography.style(
                            fontSize: 14,
                            height: 1.65,
                            color: ProfileTokens.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            bullet,
                            style: CartTypography.style(
                              fontSize: 14,
                              height: 1.65,
                              color: ProfileTokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                for (final paragraph in section.paragraphs.skip(1)) ...[
                  const SizedBox(height: 8),
                  Text(
                    paragraph,
                    style: CartTypography.style(
                      fontSize: 14,
                      height: 1.65,
                      color: ProfileTokens.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPublicUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
