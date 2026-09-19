import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matlobgo/screens/home/widgets/governorate_picker.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_governorate_service.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_bottom_nav.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_cart_drawer.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_header.dart';
import 'package:matlobgo/web/widgets/web_conversion_popup.dart';

class TarfaShell extends StatelessWidget {
  const TarfaShell({
    super.key,
    required this.state,
    required this.child,
  });

  final GoRouterState state;
  final Widget child;

  Future<void> _pickGovernorate(BuildContext context) async {
    final picked = await showGovernoratePicker(
      context,
      current: WebGovernorateService.instance.governorate,
    );
    if (picked == null || !context.mounted) return;
    await WebGovernorateService.instance.setGovernorate(picked);
    if (!context.mounted) return;
    context.go(WebConstants.governoratePath(picked.id));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < TarfaTokens.mobileBreakpoint;
    final location = state.uri.toString();
    final isStoreOrProduct = location.contains('/store/');
    final hideNav = isStoreOrProduct;
    final isProfile = location.contains('/profile');
    final govId = state.pathParameters['govId'] ?? 'cairo';

    return WebConversionPopupHost(
      child: Scaffold(
        backgroundColor: TarfaTokens.background,
        body: Stack(
          children: [
            Column(
              children: [
                if (!isMobile && !isProfile && !isStoreOrProduct)
                  TarfaHeader(
                    govId: govId,
                    onLocationTap: () => _pickGovernorate(context),
                    onSearchTap: () => context.push(
                      '${WebConstants.governoratePath(govId)}/search',
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: TarfaTokens.maxWidth,
                      ),
                      child: child,
                    ),
                  ),
                ),
                if (!hideNav && isMobile)
                  TarfaBottomNav(
                    location: location,
                    govId: govId,
                  ),
              ],
            ),
            if (!isMobile) const TarfaCartDrawer(),
            if (isMobile) const TarfaMobileCartDrawer(),
          ],
        ),
      ),
    );
  }
}
