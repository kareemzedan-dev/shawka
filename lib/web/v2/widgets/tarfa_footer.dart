import 'package:flutter/material.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/widgets/brand_logo.dart';
import 'package:matlobgo/web/config/tarfa_contact_info.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/v2/content/tarfa_legal_content.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

class TarfaFooter extends StatelessWidget {
  const TarfaFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < TarfaTokens.mobileBreakpoint;

    return Container(
      width: double.infinity,
      color: TarfaTokens.primary,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? TarfaTokens.s24 : TarfaTokens.s48,
        vertical: TarfaTokens.s56,
      ),
      child: isMobile ? _buildMobile(context) : _buildDesktop(context),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLogo(
                    width: 120,
                    style: BrandLogoStyle.onDark,
                  ),
                  const SizedBox(height: TarfaTokens.s16),
                  Text(
                    AppBranding.tagline,
                    style: TarfaTokens.bodyLarge(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: TarfaTokens.s16),
                  _AddressRow(context: context),
                  const SizedBox(height: TarfaTokens.s24),
                  Row(
                    children: [
                      _SocialButton(
                        icon: Icons.facebook_rounded,
                        onTap: () {},
                      ),
                      _SocialButton(
                        icon: Icons.camera_alt_outlined,
                        onTap: () {},
                      ),
                      _SocialButton(
                        icon: Icons.alternate_email_rounded,
                        onTap: () => _launch(TarfaContactInfo.emailMailto),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _FooterColumn(
                title: 'الشركة',
                links: [
                  (
                    'من نحن',
                    () => showTarfaLegalSheet(
                          context,
                          title: TarfaLegalContent.aboutTitle,
                          body: TarfaLegalContent.aboutBody,
                        ),
                  ),
                ],
                footer: _ContactBlock(context: context),
              ),
            ),
            Expanded(
              child: _FooterColumn(
                title: 'روابط مهمة',
                links: [
                  (
                    'الشروط والأحكام',
                    () => showTarfaLegalSheet(
                          context,
                          title: TarfaLegalContent.termsTitle,
                          body: TarfaLegalContent.termsBody,
                        ),
                  ),
                  (
                    'سياسة الخصوصية',
                    () => showTarfaLegalSheet(
                          context,
                          title: TarfaLegalContent.privacyTitle,
                          body: TarfaLegalContent.privacyBody,
                        ),
                  ),
                  (
                    'سياسة الاسترجاع',
                    () => showTarfaLegalSheet(
                          context,
                          title: TarfaLegalContent.refundTitle,
                          body: TarfaLegalContent.refundBody,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حمّل التطبيق',
                    style: TarfaTokens.titleLarge(context).copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: TarfaTokens.s16),
                  _AppStoreButton(
                    label: 'Google Play',
                    icon: Icons.android_rounded,
                    onTap: () => _launch(WebConstants.googlePlayUrl),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TarfaTokens.s48),
        Divider(color: Colors.white.withValues(alpha: 0.15)),
        const SizedBox(height: TarfaTokens.s24),
        Text(
          '© ${DateTime.now().year} ${AppBranding.displayName}. جميع الحقوق محفوظة.',
          style: TarfaTokens.bodyMedium(context).copyWith(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: BrandLogo(width: 100, style: BrandLogoStyle.onDark),
        ),
        const SizedBox(height: TarfaTokens.s24),
        Text(
          AppBranding.tagline,
          style: TarfaTokens.bodyMedium(context).copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TarfaTokens.s16),
        _AddressRow(context: context),
        const SizedBox(height: TarfaTokens.s24),
        _ContactBlock(context: context),
        const SizedBox(height: TarfaTokens.s32),
        _FooterColumn(
          title: 'روابط مهمة',
          links: [
            (
              'من نحن',
              () => showTarfaLegalSheet(
                    context,
                    title: TarfaLegalContent.aboutTitle,
                    body: TarfaLegalContent.aboutBody,
                  ),
            ),
            (
              'الشروط والأحكام',
              () => showTarfaLegalSheet(
                    context,
                    title: TarfaLegalContent.termsTitle,
                    body: TarfaLegalContent.termsBody,
                  ),
            ),
            (
              'سياسة الخصوصية',
              () => showTarfaLegalSheet(
                    context,
                    title: TarfaLegalContent.privacyTitle,
                    body: TarfaLegalContent.privacyBody,
                  ),
            ),
            (
              'سياسة الاسترجاع',
              () => showTarfaLegalSheet(
                    context,
                    title: TarfaLegalContent.refundTitle,
                    body: TarfaLegalContent.refundBody,
                  ),
            ),
          ],
        ),
        const SizedBox(height: TarfaTokens.s24),
        Text(
          'حمّل التطبيق',
          style: TarfaTokens.titleLarge(context).copyWith(color: Colors.white),
        ),
        const SizedBox(height: TarfaTokens.s12),
        _AppStoreButton(
          label: 'Google Play',
          icon: Icons.android_rounded,
          onTap: () => _launch(WebConstants.googlePlayUrl),
        ),
        const SizedBox(height: TarfaTokens.s32),
        Text(
          '© ${DateTime.now().year} ${AppBranding.displayName}',
          style: TarfaTokens.bodyMedium(context).copyWith(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 18,
          color: Colors.white.withValues(alpha: 0.65),
        ),
        const SizedBox(width: TarfaTokens.s8),
        Expanded(
          child: Text(
            TarfaContactInfo.address,
            style: TarfaTokens.bodyMedium(context).copyWith(
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactBlock extends StatelessWidget {
  const _ContactBlock({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    final linkStyle = TarfaTokens.bodyMedium(context).copyWith(
      color: Colors.white.withValues(alpha: 0.85),
      decoration: TextDecoration.underline,
      decorationColor: Colors.white.withValues(alpha: 0.4),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تواصل معنا',
          style: TarfaTokens.titleLarge(context).copyWith(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: TarfaTokens.s12),
        _ContactLink(
          icon: Icons.email_outlined,
          label: TarfaContactInfo.email,
          url: TarfaContactInfo.emailMailto,
          style: linkStyle,
        ),
        const SizedBox(height: TarfaTokens.s8),
        _ContactLink(
          icon: Icons.phone_outlined,
          label: TarfaContactInfo.phone,
          url: TarfaContactInfo.phoneTel,
          style: linkStyle,
        ),
      ],
    );
  }
}

class _ContactLink extends StatelessWidget {
  const _ContactLink({
    required this.icon,
    required this.label,
    required this.url,
    required this.style,
  });

  final IconData icon;
  final String label;
  final String url;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.65)),
            const SizedBox(width: TarfaTokens.s8),
            Text(label, style: style),
          ],
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({
    required this.title,
    required this.links,
    this.footer,
  });

  final String title;
  final List<(String, VoidCallback?)> links;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TarfaTokens.titleLarge(context).copyWith(color: Colors.white),
        ),
        const SizedBox(height: TarfaTokens.s16),
        for (final (label, onTap) in links)
          Padding(
            padding: const EdgeInsets.only(bottom: TarfaTokens.s12),
            child: _FooterLink(label: label, onTap: onTap),
          ),
        if (footer != null) ...[
          const SizedBox(height: TarfaTokens.s8),
          footer!,
        ],
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = TarfaTokens.bodyMedium(context).copyWith(
      color: Colors.white.withValues(alpha: onTap != null ? 0.85 : 0.65),
      decoration: onTap != null ? TextDecoration.underline : null,
      decorationColor: Colors.white.withValues(alpha: 0.35),
    );

    if (onTap == null) {
      return Text(label, style: style);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Text(label, style: style),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: TarfaTokens.s8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(TarfaTokens.s12),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _AppStoreButton extends StatelessWidget {
  const _AppStoreButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: TarfaTokens.borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: TarfaTokens.borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TarfaTokens.s16,
            vertical: TarfaTokens.s12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: TarfaTokens.s12),
              Text(
                label,
                style: TarfaTokens.labelLarge(context).copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
