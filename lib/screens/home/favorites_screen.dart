import 'package:flutter/material.dart';
import 'package:matlobgo/screens/home/tabs/favorites_tab.dart';
import 'package:matlobgo/services/cart_service.dart';

/// Full-screen route wrapper — same content as [FavoritesTab].
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    required this.governorateName,
    required this.cartService,
    this.onExploreStores,
  });

  final String governorateName;
  final CartService cartService;
  final VoidCallback? onExploreStores;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FavoritesTab(
        governorateName: governorateName,
        cartService: cartService,
        onExploreStores: (_) => onExploreStores?.call(),
      ),
    );
  }
}
