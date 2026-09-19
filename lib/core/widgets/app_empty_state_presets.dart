import 'package:flutter/material.dart';
import 'package:matlobgo/core/cms/cms_keys.dart';
import 'package:matlobgo/services/cms_text_service.dart';

/// Unified empty-state kinds across MatlobGo.
enum AppEmptyKind {
  ordersAll,
  ordersActive,
  ordersCompleted,
  ordersCancelled,
  favorites,
  cart,
  search,
  searchNoResults,
  notifications,
  stores,
  categories,
  menuEmpty,
  menuSearch,
  address,
  retry,
}

/// Visual + copy preset for [AppEmptyState] — icon only, no emoji overlays.
class AppEmptyStatePreset {
  const AppEmptyStatePreset({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionIcon = Icons.explore_rounded,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final IconData actionIcon;

  AppEmptyStatePreset copyWith({
    String? title,
    String? subtitle,
    String? actionLabel,
    IconData? actionIcon,
  }) {
    return AppEmptyStatePreset(
      icon: icon,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      actionLabel: actionLabel ?? this.actionLabel,
      actionIcon: actionIcon ?? this.actionIcon,
    );
  }
}

/// Design-system copy & icons — يدمج CMS عند التوفر.
abstract final class AppEmptyPresets {
  static const ordersAll = AppEmptyStatePreset(
    icon: Icons.receipt_long_rounded,
    title: 'لا توجد طلبات بعد',
    subtitle: 'اطلب من موردك المفضل وتابع طلبك خطوة بخطوة من هنا',
    actionLabel: 'ابدأ التسوق',
    actionIcon: Icons.shopping_bag_rounded,
  );

  static const ordersActive = AppEmptyStatePreset(
    icon: Icons.local_shipping_rounded,
    title: 'لا توجد طلبات نشطة',
    subtitle: 'عندما تطلب الآن ستظهر حالة طلبك ومتابعته هنا فوراً',
    actionLabel: 'ابدأ التسوق',
    actionIcon: Icons.shopping_bag_rounded,
  );

  static const ordersCompleted = AppEmptyStatePreset(
    icon: Icons.check_circle_outline_rounded,
    title: 'لم تكمل أي طلب بعد',
    subtitle: 'ستظهر طلباتك المكتملة هنا بمجرد استلامها بنجاح',
    actionLabel: 'ابدأ التسوق',
    actionIcon: Icons.shopping_bag_rounded,
  );

  static const ordersCancelled = AppEmptyStatePreset(
    icon: Icons.cancel_outlined,
    title: 'لا توجد طلبات ملغية',
    subtitle: 'أي طلبات أُلغيت ستُعرض هنا للرجوع إليها عند الحاجة',
  );

  static const favorites = AppEmptyStatePreset(
    icon: Icons.favorite_rounded,
    title: 'ابدأ بإضافة موردينك المفضلين',
    subtitle: 'احفظ الموردين والمنتجات التي تعجبك لتصل إليها بضغطة واحدة',
    actionLabel: 'استكشف الموردين',
    actionIcon: Icons.storefront_rounded,
  );

  static const cart = AppEmptyStatePreset(
    icon: Icons.shopping_cart_outlined,
    title: 'سلتك فارغة حالياً',
    subtitle: 'ابدأ بإضافة منتجاتك المفضلة من أي متجر قريب منك',
    actionLabel: 'ابدأ التسوق',
    actionIcon: Icons.add_shopping_cart_rounded,
  );

  static const search = AppEmptyStatePreset(
    icon: Icons.search_rounded,
    title: 'ابحث عن ما تحب',
    subtitle: 'اكتب اسم مورد أو منتج أو اختر تصنيفاً للبدء',
    actionLabel: 'استكشف الفئات',
    actionIcon: Icons.category_rounded,
  );

  static const searchNoResults = AppEmptyStatePreset(
    icon: Icons.search_off_rounded,
    title: 'لم نجد ما تبحث عنه',
    subtitle: 'جرّب كلمة مختلفة أو غيّر التصنيف — ربما يكون قريباً',
    actionLabel: 'مسح البحث',
    actionIcon: Icons.refresh_rounded,
  );

  static const notifications = AppEmptyStatePreset(
    icon: Icons.notifications_none_rounded,
    title: 'لا توجد إشعارات الآن',
    subtitle: 'سنُبلغك فوراً بتحديثات الطلبات والعروض المميزة',
    actionLabel: 'العودة للرئيسية',
    actionIcon: Icons.home_rounded,
  );

  static const stores = AppEmptyStatePreset(
    icon: Icons.storefront_rounded,
    title: 'لا توجد موردين هنا حالياً',
    subtitle: 'جرّب تصنيفاً آخر أو محافظة مختلفة — الموردون يُضافون باستمرار',
    actionLabel: 'استكشف الموردين',
    actionIcon: Icons.explore_rounded,
  );

  static const categories = AppEmptyStatePreset(
    icon: Icons.category_outlined,
    title: 'لا توجد تصنيفات',
    subtitle: 'جرّب محافظة أخرى أو عد لاحقاً — التصنيفات تُحدَّث باستمرار',
    actionLabel: 'استكشف الموردين',
    actionIcon: Icons.explore_rounded,
  );

  static const menuEmpty = AppEmptyStatePreset(
    icon: Icons.inventory_2_rounded,
    title: 'المنيو فارغ حالياً',
    subtitle: 'سيتم إضافة المنتجات قريباً — عد لاحقاً أو جرّب متجراً آخر',
  );

  static const menuSearch = AppEmptyStatePreset(
    icon: Icons.fastfood_outlined,
    title: 'لا توجد نتائج في المنيو',
    subtitle: 'جرّب اسم منتج آخر أو تصفح القائمة كاملة',
    actionLabel: 'مسح البحث',
    actionIcon: Icons.refresh_rounded,
  );

  static const address = AppEmptyStatePreset(
    icon: Icons.location_on_outlined,
    title: 'لم يُحدَّد عنوان بعد',
    subtitle: 'ابحث عن عنوانك أو استخدم موقعك الحالي لإتمام الطلب',
    actionLabel: 'إضافة عنوان',
    actionIcon: Icons.add_location_alt_rounded,
  );

  static const retry = AppEmptyStatePreset(
    icon: Icons.refresh_rounded,
    title: 'تعذّر تحميل البيانات',
    subtitle: 'تحقق من الاتصال بالإنترنت وحاول مرة أخرى',
    actionLabel: 'إعادة المحاولة',
    actionIcon: Icons.refresh_rounded,
  );

  static AppEmptyStatePreset forKind(AppEmptyKind kind) {
    final cms = CmsTextService.instance;
    final base = _baseForKind(kind);
    return switch (kind) {
      AppEmptyKind.ordersAll => base.copyWith(
          title: cms.resolve(CmsKeys.emptyOrders, fallback: base.title),
        ),
      AppEmptyKind.favorites => base.copyWith(
          title: cms.resolve(CmsKeys.emptyFavorites, fallback: base.title),
        ),
      AppEmptyKind.cart => base.copyWith(
          title: cms.resolve(CmsKeys.emptyCartTitle, fallback: base.title),
          subtitle: cms.resolve(CmsKeys.emptyCartSubtitle, fallback: base.subtitle),
        ),
      _ => base,
    };
  }

  static AppEmptyStatePreset _baseForKind(AppEmptyKind kind) => switch (kind) {
        AppEmptyKind.ordersAll => ordersAll,
        AppEmptyKind.ordersActive => ordersActive,
        AppEmptyKind.ordersCompleted => ordersCompleted,
        AppEmptyKind.ordersCancelled => ordersCancelled,
        AppEmptyKind.favorites => favorites,
        AppEmptyKind.cart => cart,
        AppEmptyKind.search => search,
        AppEmptyKind.searchNoResults => searchNoResults,
        AppEmptyKind.notifications => notifications,
        AppEmptyKind.stores => stores,
        AppEmptyKind.categories => categories,
        AppEmptyKind.menuEmpty => menuEmpty,
        AppEmptyKind.menuSearch => menuSearch,
        AppEmptyKind.address => address,
        AppEmptyKind.retry => retry,
      };
}
