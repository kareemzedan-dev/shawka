import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/checkout_tokens.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/models/checkout_quote.dart';
import 'package:matlobgo/models/delivery_address.dart';
import 'package:matlobgo/screens/home/checkout/widgets/checkout_section.dart';

class CheckoutAddressCard extends StatelessWidget {
  const CheckoutAddressCard({
    super.key,
    required this.palette,
    required this.address,
    required this.quote,
    required this.onEdit,
    required this.changeLabel,
    required this.addAddressLabel,
  });

  final AppPalette palette;
  final DeliveryAddress? address;
  final CheckoutQuote? quote;
  final VoidCallback onEdit;
  final String changeLabel;
  final String addAddressLabel;

  @override
  Widget build(BuildContext context) {
    final hasAddress = address?.hasCoordinates == true;
    return CheckoutSurfaceCard(
      palette: palette,
      child: Column(
        children: [
          if (hasAddress)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(CheckoutTokens.radiusXl),
              ),
              child: SizedBox(
                height: CheckoutTokens.mapPreviewHeight + 12,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    IgnorePointer(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(address!.latitude, address!.longitude),
                          zoom: 15.5,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('delivery-address'),
                            position: LatLng(
                              address!.latitude,
                              address!.longitude,
                            ),
                          ),
                        },
                        liteModeEnabled: true,
                        mapToolbarEnabled: false,
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        compassEnabled: false,
                      ),
                    ),
                    PositionedDirectional(
                      start: CheckoutTokens.spaceLg,
                      top: CheckoutTokens.spaceLg,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            CheckoutTokens.radiusXl,
                          ),
                          boxShadow: HomeTheme.softShadow(palette),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CheckoutTokens.spaceLg,
                            vertical: 7,
                          ),
                          child: Text(
                            address?.area.isNotEmpty == true
                                ? address!.area
                                : address?.governorate ?? '',
                            style: CartTypography.style(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(CheckoutTokens.space2xl),
            child: hasAddress
                ? Column(
                    children: [
                      Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.11),
                              borderRadius: BorderRadius.circular(
                                CheckoutTokens.radiusSm,
                              ),
                            ),
                            child: const SizedBox(
                              width: 42,
                              height: 42,
                              child: Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 23,
                              ),
                            ),
                          ),
                          const SizedBox(width: CheckoutTokens.spaceLg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  address?.displayLine ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CartTypography.style(
                                    fontSize: 14.5,
                                    height: 1.35,
                                    fontWeight: FontWeight.w800,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  address?.shortLine ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: CartTypography.style(
                                    fontSize: 12.5,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: CheckoutTokens.spaceSm),
                          Semantics(
                            button: true,
                            label: changeLabel,
                            child: OutlinedButton(
                              onPressed: onEdit,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(
                                  CheckoutTokens.touchTarget,
                                  42,
                                ),
                                side: BorderSide(color: palette.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                              child: Text(
                                changeLabel,
                                style: CartTypography.style(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: DeliveryChip(
                              icon: Icons.schedule_rounded,
                              value: '${quote?.etaMinutes ?? 0} د',
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: DeliveryChip(
                              icon: Icons.route_rounded,
                              value:
                                  '${quote?.distanceKm.toStringAsFixed(1) ?? '0'} كم',
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: DeliveryChip(
                              icon: Icons.delivery_dining_rounded,
                              value: quote != null && quote!.deliveryFee == 0
                                  ? 'مجاني'
                                  : '${quote?.deliveryFee.toStringAsFixed(0) ?? '0'} ج.م',
                              highlighted:
                                  quote != null && quote!.deliveryFee == 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: Semantics(
                      button: true,
                      label: addAddressLabel,
                      child: FilledButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.add_location_alt_rounded),
                        label: Text(
                          addAddressLabel,
                          style: CartTypography.style(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class DeliveryChip extends StatelessWidget {
  const DeliveryChip({
    super.key,
    required this.icon,
    required this.value,
    this.highlighted = false,
  });

  final IconData icon;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.success : AppColors.navy;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(CheckoutTokens.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: CheckoutTokens.spaceMd - 1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: CheckoutTokens.spaceXs),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CartTypography.style(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
