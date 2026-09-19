import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/profile_tokens.dart';

class ProfileQuickActionItem {
  const ProfileQuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class ProfileQuickActionsSection extends StatelessWidget {
  const ProfileQuickActionsSection({super.key, required this.actions});

  final List<ProfileQuickActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'وصول سريع',
          style: CartTypography.style(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: ProfileTokens.navy,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length.clamp(0, 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.35,
          ),
          itemBuilder: (context, i) {
            final a = actions[i];
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ProfileTokens.actionRadius),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  a.onTap();
                },
                borderRadius:
                    BorderRadius.circular(ProfileTokens.actionRadius),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(ProfileTokens.actionRadius),
                    border: Border.all(color: ProfileTokens.cardBorder),
                    boxShadow: ProfileTokens.softShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        a.icon,
                        size: 22,
                        color: ProfileTokens.actionIcon,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          a.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CartTypography.style(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: ProfileTokens.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
