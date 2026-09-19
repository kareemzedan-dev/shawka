import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

void main() {
  test('شوكة و سكينة brand colors match official logo palette', () {
    expect(AppColors.primary, const Color(0xFFD4AF37));
    expect(AppColors.primaryLight, const Color(0xFFF1D27B));
    expect(AppColors.primaryDark, const Color(0xFF8E6D2F));
    expect(AppColors.navy, const Color(0xFF0A0A0A));
  });
}
