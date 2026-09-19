import 'package:flutter/material.dart';
import 'package:matlobgo/config/branding/generated/branding_values.g.dart';
import 'package:matlobgo/core/constants/app_assets.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/models/store.dart';

abstract final class MockHomeData {
  static List<Governorate> get governorates => EgyptGovernorates.all;

  static const promoBanners = [
    PromoBanner(
      id: '1',
      title: 'توصيل مجاني',
      subtitle: 'على أول 3 طلبات من ${BrandingValues.appName}',
      cta: 'اطلب دلوقتي',
      imageAsset: AppAssets.bannerDelivery,
    ),
    PromoBanner(
      id: '2',
      title: 'خصم 20%',
      subtitle: 'على منتجات الجملة من أفضل الموردين',
      cta: 'اكتشف العروض',
      imageAsset: AppAssets.bannerDiscount,
      accentColor: Color(0xFFD4AF37),
    ),
    PromoBanner(
      id: '3',
      title: 'توريد بالجملة',
      subtitle: 'مواد غذائية لشركتك ومحلك من موردين موثوقين',
      cta: 'تصفّح الموردين',
      imageAsset: AppAssets.bannerDelivery,
      accentColor: Color(0xFF1565C0),
    ),
  ];

  static const stores = [
    Store(
      id: '1',
      name: 'شركة النيل للتموين',
      categoryId: 'dry_goods',
      rating: 4.8,
      deliveryMinutes: 45,
      deliveryFee: 25,
      fallbackOpen: true,
      tags: ['جملة', 'تموين'],
      governorate: 'القاهرة',
      isFeatured: true,
      discountLabel: 'خصم 15%',
    ),
    Store(
      id: '2',
      name: 'مورد الزيوت المتحدة',
      categoryId: 'oils',
      rating: 4.6,
      deliveryMinutes: 40,
      deliveryFee: 20,
      fallbackOpen: true,
      tags: ['زيوت', 'جملة'],
      governorate: 'القاهرة',
      isFeatured: true,
    ),
    Store(
      id: '3',
      name: 'شركة الدلتا للألبان',
      categoryId: 'dairy',
      rating: 4.7,
      deliveryMinutes: 35,
      deliveryFee: 18,
      fallbackOpen: true,
      tags: ['ألبان', 'جبن'],
      governorate: 'القاهرة',
    ),
    Store(
      id: '4',
      name: 'توريد الخضروات الطازجة',
      categoryId: 'produce',
      rating: 4.5,
      deliveryMinutes: 50,
      deliveryFee: 22,
      fallbackOpen: true,
      tags: ['خضار', 'فاكهة'],
      governorate: 'القاهرة',
      discountLabel: 'عرض اليوم',
    ),
    Store(
      id: '5',
      name: 'شركة الشرق للحوم',
      categoryId: 'meat',
      rating: 4.9,
      deliveryMinutes: 55,
      deliveryFee: 30,
      fallbackOpen: true,
      tags: ['لحوم', 'دواجن'],
      governorate: 'القاهرة',
      isFeatured: true,
    ),
    Store(
      id: '6',
      name: 'موردات المخابز الكبرى',
      categoryId: 'bakery_supplies',
      rating: 4.4,
      deliveryMinutes: 40,
      deliveryFee: 20,
      fallbackOpen: true,
      tags: ['دقيق', 'خميرة'],
      governorate: 'القاهرة',
    ),
  ];
}
