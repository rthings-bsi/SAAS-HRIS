import 'package:flutter/material.dart';

class AppDimensions {
  AppDimensions._();

  // Spacing (Multiples of 4px / 8px)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Touch Target (DESIGN.md 1.6 #6 & R-03: min 48px)
  static const double minTouchTarget = 48.0;

  // Border Radius (Modern SaaS Mobile UI/UX: rounded-xl 12px, rounded-2xl 16px)
  static const double radiusInput = 12.0;
  static const double radiusButton = 12.0;
  static const double radiusCard = 16.0;
  static const double radiusModal = 20.0;

  static const BorderRadius inputBorderRadius = BorderRadius.all(Radius.circular(radiusInput));
  static const BorderRadius buttonBorderRadius = BorderRadius.all(Radius.circular(radiusButton));
  static const BorderRadius cardBorderRadius = BorderRadius.all(Radius.circular(radiusCard));
  static const BorderRadius modalBorderRadius = BorderRadius.all(Radius.circular(radiusModal));

  // Border Width
  static const double borderWidth = 1.0;
}
