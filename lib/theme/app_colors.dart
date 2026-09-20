import 'package:flutter/material.dart';

/// Status colors used consistently across monitors, alerts, and clusters.
class AppColors {
  static const online = Color(0xFF22C55E);
  static const offline = Color(0xFFEF4444);
  static const paused = Color(0xFFF59E0B);
  static const warning = Color(0xFFF59E0B);

  static const radius = 16.0;
  static const radiusMd = 14.0;
  static const radiusSm = 12.0;
  static const radiusXs = 10.0;

  static Color statusFor({
    required bool paused,
    required bool online,
  }) {
    if (paused) return AppColors.paused;
    return online ? AppColors.online : AppColors.offline;
  }
}
