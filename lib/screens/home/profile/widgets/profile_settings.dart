import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/profile_tokens.dart';

class ProfileSettingsTileData {
  const ProfileSettingsTileData({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;
}

class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({
    super.key,
    required this.title,
    required this.tiles,
  });

  final String title;
  final List<ProfileSettingsTileData> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: CartTypography.style(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: ProfileTokens.navy,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ProfileTokens.settingsRadius),
            border: Border.all(color: ProfileTokens.cardBorder),
            boxShadow: ProfileTokens.softShadow,
          ),
          child: Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    indent: 56,
                    color: ProfileTokens.cardBorder,
                  ),
                _SettingsRow(data: tiles[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.data});

  final ProfileSettingsTileData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(ProfileTokens.settingsRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(data.icon, size: 22, color: ProfileTokens.navy),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.label,
                  style: CartTypography.style(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ProfileTokens.textPrimary,
                  ),
                ),
              ),
              if (data.trailing != null) data.trailing!,
              if (data.showChevron && data.trailing == null)
                const Icon(
                  Icons.chevron_left_rounded,
                  color: ProfileTokens.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileDarkModeSwitch extends StatelessWidget {
  const ProfileDarkModeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: ProfileTokens.accent,
    );
  }
}

class ProfileLogoutFooter extends StatelessWidget {
  const ProfileLogoutFooter({
    super.key,
    required this.label,
    required this.onTap,
    required this.version,
    this.isLogin = false,
  });

  final String label;
  final VoidCallback onTap;
  final String version;
  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: ProfileTokens.accent,
            side: const BorderSide(color: ProfileTokens.accent, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLogin ? Icons.login_rounded : Icons.logout_rounded,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: CartTypography.style(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ProfileTokens.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'الإصدار $version • صنع بحب',
          textAlign: TextAlign.center,
          style: CartTypography.style(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ProfileTokens.textMuted,
          ),
        ),
      ],
    );
  }
}
